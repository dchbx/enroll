# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module FinancialAssistance
  module Operations
    module Applicant
      class Delete
        send(:include, Dry::Monads[:result, :do])
        send(:include, Dry::Monads[:try])

        def call(financial_applicant: , family_id: )
          values        = yield validate(financial_applicant)
          application   = yield find_draft_application(family_id)
          applicant     = yield match_applicant(values, application)
          result        = yield delete_applicant(applicant)

          Success(result)
        end

        private

        def validate(params)
          result = ::FinancialAssistance::Validators::ApplicantContract.new.call(params)

          if result.success?
            Success(result.to_h)
          else
            Failure(result)
          end
        end

        def find_draft_application(family_id)
          application =  ::FinancialAssistance::Application.where(family_id: family_id, aasm_state: 'draft').first
          if application
            Success(application)
          else
            Failure("Application Not Found")
          end
        end

        def match_applicant(financial_applicant, application)
          result = ::FinancialAssistance::Operations::Applicant::Match.new.call(params: financial_applicant, application: application)
          result.success? ? Success(result.success) : Failure(result.failure)
        end

        def delete_applicant(applicant)
          Try { applicant&.destroy! }
        end
      end
    end
  end
end