# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module FinancialAssistance
  module Operations
    module Applicant
      class CreateOrUpdate
        send(:include, Dry::Monads[:result, :do])

        #applicant attributes as type
        def call(params:, family_id:)
          values      = yield validate(params)
          application = yield find_draft_application(family_id)
          applicant   = yield match_or_build(values, application)
          # difference  = yield compare_values(values, applicant)
          result      = yield update(applicant, values)

          Success(result)
        end

        private

        def validate(params)
          ::FinancialAssistance::Validators::ApplicantContract.new.call(params)
        end

        def find_draft_application(family_id)
          application = ::FinancialAssistance::Application.where(family_id: family_id, aasm_state: 'draft').first
          if application
            Success(application)
          else
            Failure("Application Not Found")
          end
        end

        def match_or_build(values, application)
          result = ::FinancialAssistance::Operations::Applicant::Match.new.call(params: values.to_h, application: application)

          if result.success?
            Success(result.success)
          else
            Success(application.applicants.build(values.to_h))
          end
        end

        def compare_values(values, applicant)

          # use #serializable_hash ?
          # diff = applicant.serializable_hash.merge(values.to_h.deep_stringify_keys) { |key, val_1, val_2| val_1 == val_2 ? nil : :different }.compact.keys
          # diff = applicant.as_document.merge(values.to_h.deep_stringify_keys) { |key, val_1, val_2| val_1 == val_2 ? nil : :different }.compact.keys
          # diff = values.to_h.deep_stringify_keys.merge(applicant.as_document) { |key, val_1, val_2| val_1 == val_2 ? nil : :different }.keys

          # diff = applicant.serializable_hash.reject{ |k,v| values.to_h[k] == v}
          # diff = values.to_h.reject { | k, v | applicant.serializable_hash[k] == v }

          # require 'pry'; binding.pry          
          # diff.empty? ? Failure('noop') : Success(nil)
        end

        def update(applicant, values)
          applicant.assign_attributes(values.to_h)

          if applicant.persist!
            Success(applicant)
          else
            Failure(applicant.errors)
          end
        end
      end
    end
  end
end
