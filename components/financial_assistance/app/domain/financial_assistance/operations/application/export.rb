# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module FinancialAssistance
  module Operations
    module Application
      class Export
        send(:include, Dry::Monads[:result, :do])

        # @param [ FinancialAssistance::Application ] application Applicant Attributes
        # @return [ Hash ] payload Application Payload
        def call(application:)
          payload = yield export(application)

          Success(payload)
        end

        private

        def export(application)
          payload = application.attributes.slice(:family_id, :effective_date)
          payload[:applicants] = application.applicants.collect {|applicant| applicant.attributes_for_export }
          payload[:relationships] = application.relationships.collect {|relationship| relationship.attributes.except(:_id, :created_at, :updated_at) }

          Success(payload)
        end
      end
    end
  end
end