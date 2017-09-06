module Subscribers
  class FinancialAssistanceApplicationEligibilityResponse < ::Acapi::Subscription
    include Acapi::Notifiers

    ELIGIBILITY_SCHEMA_FILE_PATH = File.join(Rails.root, 'lib', 'schemas', 'financial_assistance.xsd')

    def self.subscription_details
      ["acapi.info.events.assistance_application.application_processed"]
    end

    def call(event_name, e_start, e_end, msg_id, payload)
      stringed_key_payload = payload.stringify_keys
      xml = stringed_key_payload["body"]
      application = FinancialAssistance::Application.where(:id => stringed_key_payload["assistance_application_id"]).first if stringed_key_payload["assistance_application_id"].present?
      if application.present?
        payload_http_status_code = stringed_key_payload["return_status"]
        application.update_attributes(determination_http_status_code: payload_http_status_code)
        if application.success_status_codes?(payload_http_status_code.to_i)
          if eligibility_payload_schema_valid?(xml)
            sc = ShortCircuit.on(:processing_issue) do |err|
              log(xml, {:severity => "critical", :error_message => err})
            end
            sc.and_then do |payload|
              haven_import_from_xml(payload)
            end
            sc.call(xml)
          else
            log(xml, {:severity => "critical", :error_message => "ERROR: Failed to validate the XML against FAA XSD"})
          end
        else
          error_message = stringed_key_payload["body"]
          application.set_determination_response_error!
          application.update_attributes(determination_http_status_code: payload_http_status_code, determination_error_message: error_message)
        end
      else
        log(xml, {:severity => "critical", :error_message => "ERROR: Failed to find the Application in XML"})
      end
    end

    def haven_import_from_xml(xml)
      verified_family = Parsers::Xml::Cv::HavenVerifiedFamilyParser.new
      verified_family.parse(xml)
      verified_primary_family_member = verified_family.family_members.detect{ |fm| fm.person.hbx_id == verified_family.primary_family_member_id }
      verified_dependents = verified_family.family_members.reject{ |fm| fm.person.hbx_id == verified_family.primary_family_member_id }
      primary_person = search_person(verified_primary_family_member)
      throw(:processing_issue, "ERROR: Failed to find primary person in xml") unless primary_person.present?
      family = primary_person.primary_family
      throw(:processing_issue, "ERROR: Failed to find primary family for users person in xml") unless family.present?
      stupid_family_id = family.id
      active_household = family.active_household
      family.save! # In case the tax household does not exist
      #        family = Family.find(stupid_family_id) # wow
      #        active_household = family.active_household

      application_in_context = family.applications.where(:id => verified_family.fin_app_id).first
      throw(:processing_issue, "ERROR: Failed to find application for person in xml") unless application_in_context.present?
      active_verified_household = verified_family.households.max_by(&:start_date)
      verified_dependents.each do |verified_family_member|
        throw(:processing_issue, "Failed to find dependent from xml") unless search_person(verified_family_member).present?
      end

      primary_person = search_person(verified_primary_family_member) #such mongoid
      family.save!

      family.e_case_id = verified_family.integrated_case_id
      begin
        active_household.build_or_update_tax_households_and_applicants_and_eligibility_determinations(verified_family, primary_person, active_verified_household, application_in_context)
      rescue
        throw(:processing_issue, "Failure to update tax household")
      end
      begin
        if application_in_context.tax_households.present?
          unless application_in_context.eligibility_determinations.present?
            log("ERROR: No eligibility_determinations found for tax_household: #{xml}", {:severity => "error"})
          end
        end
      rescue
        log("ERROR: Unable to create tax household from xml: #{xml}", {:severity => "error"})
      end
      family.save!
      application_in_context.determine!
    end

    def search_person(verified_family_member)
      ssn = verified_family_member.person_demographics.ssn
      ssn = '' if ssn == "999999999"
      dob = verified_family_member.person_demographics.birth_date
      last_name_regex = /^#{verified_family_member.person.name_last}$/i
      first_name_regex = /^#{verified_family_member.person.name_first}$/i

      if !ssn.blank?
        Person.where({
          :encrypted_ssn => Person.encrypt_ssn(ssn),
          :dob => dob
        }).first
      else
        Person.where({
          :dob => dob,
          :last_name => last_name_regex,
          :first_name => first_name_regex
        }).first
      end
    end

    def eligibility_payload_schema_valid?(xml)
      return false if xml.blank?
      xml = Nokogiri::XML.parse(xml)
      xsd = Nokogiri::XML::Schema(File.open ELIGIBILITY_SCHEMA_FILE_PATH)
      xsd.valid?(xml)
    end
  end
end