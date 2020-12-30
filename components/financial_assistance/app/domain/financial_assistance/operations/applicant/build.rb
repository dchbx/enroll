# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module FinancialAssistance
  module Operations
    module Applicant
      class Build
        send(:include, Dry::Monads[:result, :do])

        # @param [ Hash ] params Applicant Attributes
        # @return [FinancialAssistance::Entities::Applicant ] applicant Applicant
        def call(params:)
          values     = yield validate(params)
          applicant  = yield build(values)

          Success(applicant)
        end

        private

        def validate(params)
          result = FinancialAssistance::Validators::ApplicantContract.new.call(params)

          if result.success?
            Success(result.to_h)
          else
            Failure(result)
          end
        end

        def build(values)
          applicant_entity = FinancialAssistance::Entities::Applicant.new(values)

          Success(applicant_entity)
        end
      end
    end
  end
end