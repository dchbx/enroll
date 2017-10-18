module Subscribers
  class FinancialAssistanceApplicationOutstandingVerification < ::Acapi::Subscription
    include Acapi::Notifiers

    VERIFICATION_SCHEMA_FILE_PATH = File.join(Rails.root, 'lib', 'schemas', 'verification_services.xsd')

    def self.subscription_details
      ["acapi.info.events.outstanding_verification.submitted"]
    end

    def call(event_name, e_start, e_end, msg_id, payload)
      stringed_key_payload = payload.stringify_keys
      xml = stringed_key_payload["body"]

      application = FinancialAssistance::Application.where(id: stringed_key_payload["assistance_application_id"]).first if stringed_key_payload["assistance_application_id"].present?
      if application.present? && application.aasm_state == "determined"

        if verification_payload_schema_valid?(xml)
          sc = ShortCircuit.on(:processing_issue) do |err|
            log(xml, {:severity => "critical", :error_message => err})
          end
          sc.and_then do |payload|
            haven_verifications_import_from_xml(payload)
          end
          sc.call(xml)
        else
          #Rejection message to Haven on failed Schema Validation
          message = "Invalid schema eligibility determination response provided"
          notify("acapi.info.events.verification.rejected",
                    #Same correlation_id is sent back so that Haven can track the correct response.
                    {:correlation_id => stringed_key_payload["correlation_id"],
                      :body => JSON.dump({error: message}),
                      :assistance_application_id => stringed_key_payload["assistance_application_id"],
                      :family_id => stringed_key_payload["family_id"],
                      :primary_applicant_id => stringed_key_payload["primary_applicant_id"],
                      :haven_application_id => stringed_key_payload["haven_application_id"],
                      :haven_ic_id => stringed_key_payload["haven_ic_id"],
                      :reject_status => 422,
                      :submitted_timestamp => TimeKeeper.date_of_record.strftime('%Y-%m-%dT%H:%M:%S')})

          log(xml, {:severity => "critical", :error_message => "ERROR: Failed to validate Verification response XML"})
        end
      else
        log(xml, {:severity => "critical", :error_message => "ERROR: Failed to find the Application or Determined Application in XML"})
      end
    end

    private

    def haven_verifications_import_from_xml(xml)
      if xml.include?('income_verification_result')
        verified_income_verification = Parsers::Xml::Cv::OutstandingIncomeVerificationParser.new
        verified_income_verification.parse(xml)
        verified_person = verified_income_verification.verifications.first.individual
        import_assisted_verification("Income", verified_person, verified_income_verification)
      elsif xml.include?('mec_verification_result')
        verified_mec_verfication = Parsers::Xml::Cv::OutstandingMecVerificationParser.new
        verified_mec_verfication.parse(xml)
        verified_person = verified_mec_verfication.verifications.first.individual
        import_assisted_verification("MEC", verified_person, verified_mec_verfication)
      end
    end

    def import_assisted_verification(kind, verified_person, verified_verification)
      person_in_context = search_person(verified_person)
      throw(:processing_issue, "ERROR: Failed to find primary person in xml") unless person_in_context.present?

      application_in_context = FinancialAssistance::Application.find(verified_verification.fin_app_id)
      applicant_in_context = application_in_context.applicants.select { |applicant| applicant.person.hbx_id == person_in_context.hbx_id}.first
      throw(:processing_issue, "ERROR: Failed to find applicant in xml") unless applicant_in_context.present?

      if kind == "Income"
        applicant_in_context.update_attributes(has_income_verification_response: true)
        verification_failed = verified_verification.verifications.first.income_verification_failed
      elsif kind == "MEC"
        applicant_in_context.update_attributes(has_mec_verification_response: true)
        verification_failed = verified_verification.verifications.first.mec_verification_failed
      end

      status = verified_verification.verifications.first.response_code.split('#').last
      assisted_verification = applicant_in_context.assisted_verifications.where(verification_type: kind).first

      if assisted_verification.present?
        if assisted_verification.status == "pending"
          assisted_verification.update_attributes(status: status, verification_failed: verification_failed)
        else
          new_assisted_verification = applicant_in_context.assisted_verifications.create!(verification_type: kind, status: status, verification_failed: verification_failed)
          applicant_in_context.person.consumer_role.assisted_verification_documents.create(application_id: verified_verification.fin_app_id, applicant_id: applicant_in_context.id, assisted_verification_id: new_assisted_verification.id, status: new_assisted_verification.status, kind: new_assisted_verification.verification_type)
        end

        update_consumer_role(kind, applicant_in_context, status)
      else
        throw(:processing_issue, "ERROR: Failed to find #{kind} verification for the applicant") unless assisted_verification.present?
      end
      person_in_context.save
      application_in_context.save
    end

    def update_consumer_role(kind, applicant, status)
      consumer_role = applicant.person.consumer_role
      if kind == "Income"
        if status == "outstanding"
          consumer_role.invalid_income_response
          consumer_role.income_outstanding
        elsif status == "verified"
          consumer_role.invalid_income_response
          consumer_role.income_valid
        end
      elsif kind == "MEC"
        if status == "outstanding"
          consumer_role.invalid_mec_response
          consumer_role.mec_outstanding
        elsif status == "verified"
          consumer_role.invalid_mec_response
          consumer_role.mec_valid
        end
      end
      consumer_role.save
    end

    def search_person(verified_person)
      ssn = verified_person.person_demographics.ssn
      ssn = '' if ssn == "999999999"
      dob = verified_person.person_demographics.birth_date
      last_name_regex = /^#{verified_person.person.name_last}$/i
      first_name_regex = /^#{verified_person.person.name_first}$/i

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

    def verification_payload_schema_valid?(xml)
      return false if xml.blank?
      xml = Nokogiri::XML.parse(xml)
      xsd = Nokogiri::XML::Schema(File.open VERIFICATION_SCHEMA_FILE_PATH)
      xsd.valid?(xml)
    end
  end
end