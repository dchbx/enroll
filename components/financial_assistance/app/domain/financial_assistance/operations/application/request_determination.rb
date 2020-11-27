# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module FinancialAssistance
  module Operations
    module Application
      class RequestDetermination
        send(:include, Dry::Monads[:result, :do])
        include Acapi::Notifiers
        require 'securerandom'

        FAA_SCHEMA_FILE_PATH = File.join(FinancialAssistance::Engine.root, 'lib', 'schemas', 'financial_assistance.xsd')
        FAA_FLEXIBLE_SCHEMA_FILE_PATH = File.join(FinancialAssistance::Engine.root, 'lib', 'schemas', 'financial_assistance_flexible.xsd')

        # @param [ Hash ] params Applicant Attributes
        # @return [ BenefitMarkets::Entities::Applicant ] applicant Applicant
        def call(application_id:)
          application    = yield find_application(application_id)
          application    = yield validate(application)
          payload_param  = yield construct_payload(application)
          payload_value  = yield validate_payload(payload_param)
          payload        = yield publish(payload_value, application)

          Success(payload)
        end

        private

        def find_application(application_id)
          application = FinancialAssistance::Application.find(application_id)

          Success(application)
        rescue Mongoid::Errors::DocumentNotFound
          Failure("Unable to find Application with ID #{application_id}.")
        end

        def validate(application)
          return Success(application) if application.submitted?
          Failure("Application is in #{application.aasm_state} state. Please submit application.")
        end

        def construct_payload(application)
          payload = ::FinancialAssistance::ApplicationController.new.render_to_string(
            "financial_assistance/events/financial_assistance_application",
            :formats => ["xml"],
            :locals => { :financial_assistance_application => application }
          )

          Success(payload)
        end

        def validate_payload(payload)
          payload_xml = Nokogiri::XML.parse(payload)
          schema_path = if payload_xml.xpath("//xmlns:is_coverage_applicant").collect(&:text).include?('false')
                          FAA_FLEXIBLE_SCHEMA_FILE_PATH
                        else
                          FAA_SCHEMA_FILE_PATH
                        end

          xml_schema = Nokogiri::XML::Schema(File.open(schema_path))
          if xml_schema.valid?(payload_xml)
            Success(payload)
          else
            Failure(xml_schema.validate(payload_xml).map(&:message))
          end
        end

        # change the operation name to request_eligibility_determination
        #change the method name as request_eligibility_determination
        def publish(payload, application)
          notify("acapi.info.events.assistance_application.submitted", {
                   :correlation_id => SecureRandom.uuid.gsub("-",""),
                   :body => payload,
                   :family_id => application.family_id.to_s,
                   :assistance_application_id => application.hbx_id.to_s
                 })
          Success(payload)
        end
      end
    end
  end
end
