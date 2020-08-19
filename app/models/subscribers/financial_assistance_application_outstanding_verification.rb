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
      return_status = stringed_key_payload["return_status"].to_s

      application = FinancialAssistance::Application.where(id: stringed_key_payload["assistance_application_id"]).first if stringed_key_payload["assistance_application_id"].present?


      if return_status.to_s == "503"
        move_applicants_to_outstanding(application)
        return
      end

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
                    #Same correlation_id is sent back so that Haven can match the response sent to Enroll.
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

    # private
    def store_payload(kind, xml)
      @applicant_in_context.build_income_response({received_at: Time.now, body: xml}) if kind == 'Income'
      @applicant_in_context.build_mec_response({received_at: Time.now, body: xml}) if kind == 'MEC'

      @applicant_in_context.save!
    end

    def haven_verifications_import_from_xml(xml)
      if xml.include?('income_verification_result')
        verified_income_verification = Parsers::Xml::Cv::OutstandingIncomeVerificationParser.new
        verified_income_verification.parse(xml)
        verified_income_verification.verifications.each do |verification|
          verified_person = verification.individual
          import_assisted_verification("Income", verified_person, verified_income_verification)
          store_payload("Income", xml)
        end
      elsif xml.include?('mec_verification_result')
        verified_mec_verfication = Parsers::Xml::Cv::OutstandingMecVerificationParser.new
        verified_mec_verfication.parse(xml)
        verified_mec_verfication.verifications.each do |verification|
          verified_person = verification.individual
          import_assisted_verification("MEC", verified_person, verified_mec_verfication)
          store_payload("MEC", xml)
        end
      end
    end

    def import_assisted_verification(kind, verified_person, verified_verification)
      person_in_context = search_person(verified_person)
      throw(:processing_issue, "ERROR: Failed to find primary person in xml") unless person_in_context.present?
      application_in_context = FinancialAssistance::Application.find(verified_verification.fin_app_id)
      @applicant_in_context = application_in_context.applicants.select { |applicant| applicant.person.hbx_id == person_in_context.hbx_id}.first
      throw(:processing_issue, "ERROR: Failed to find applicant in xml") unless @applicant_in_context.present?

      @applicant_in_context.update_attributes(has_income_verification_response: true) if kind == "Income"
      @applicant_in_context.update_attributes(has_mec_verification_response: true) if kind == "MEC"

      status = verified_verification.verifications.first.response_code.split('#').last
      update_applicant(kind, @applicant_in_context, status)
      application_in_context.save!
    end

    def move_applicants_to_outstanding(application)
      return unless application.present?
      application.active_applicants.each do |applicant|
        if !applicant.has_income_verification_response && !applicant.has_mec_verification_response
          applicant.income_outstanding!
          applicant.mec_outstanding!
        elsif !applicant.has_mec_verification_response
          applicant.mec_outstanding!
        elsif !applicant.has_income_verification_response
          applicant.income_outstanding!
        end
      end
    end

    def update_applicant(kind, applicant, status)
      if kind == "Income"
        if status == "outstanding"
          applicant.invalid_income_response
          applicant.income_outstanding
        elsif status == "verified"
          applicant.invalid_income_response
          applicant.income_valid
        end
      elsif kind == "MEC"
        if status == "outstanding"
          applicant.invalid_mec_response
          applicant.mec_outstanding
        elsif status == "verified"
          applicant.invalid_mec_response
          applicant.mec_valid
        end
      end
      applicant.save!
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