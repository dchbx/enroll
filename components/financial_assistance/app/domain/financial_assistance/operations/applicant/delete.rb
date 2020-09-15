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
          application   = yield find_draft_application(family_id)
          applicant     = yield match_applicant(financial_applicant, application)
          result        = yield delete_applicant(applicant)

          Success(result)
        end

        private

        def find_draft_application(family_id)
          Try { ::FinancialAssistance::Application.where(family_id: family_id, aasm_state: 'draft').first }
        end

        def match_applicant(financial_applicant, application)
          result = ::FinancialAssistance::Operations::Applicant::Match.new.call(params: financial_applicant, application: application)
          result.success? ? Success(result.success) : Failure(result.failure)
        end

        def delete_applicant(applicant)
          Try { applicant.destroy! }
        end
      end
    end
  end
end