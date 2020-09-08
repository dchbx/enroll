# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module FinancialAssistance
  module Operations
    module Applicant
      class Build
        send(:include, Dry::Monads[:result, :do])

        # @param [ Hash ] params Applicant Attributes
        # @return [ BenefitMarkets::Entities::Applicant ] applicant Applicant
        def call(params:)
          values   = yield validate(params)
          product  = yield build(values)

          Success(product)
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
          benefit_sponsorship_entity = FinancialAssistance::Entities::Applicant.new(values)

          Success(benefit_sponsorship_entity)
        end
      end
    end
  end
end