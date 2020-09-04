# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module FinancialAssistance
  module Operations
    module Applicant
      class Create
        send(:include, Dry::Monads[:result, :do])

        # @param [ Hash ] params Applicant Attributes
        # @return [ BenefitMarkets::Entities::Applicant ] applicant Applicant
        def call(params:)
          values   = yield validate(params)
          product  = yield create(values)
          
          Success(product)
        end

        private
  
        def validate(params)
          options = merge_nested_record_arrays(params)
          result = FinancialAssistance::Validators::ApplicantContract.new.call(options)
          
          if result.success?
            Success(result.to_h)
          else
            Failure(result)
          end
        end

        def create(values)
          benefit_sponsorship_entity = FinancialAssistance::Entities::Applicant.new(values)

          Success(benefit_sponsorship_entity)
        end

        def merge_nested_record_arrays(params)
          params.merge({
            addresses: params[:addresses_attributes].values,
            emails: params[:emails_attributes].values,
            phones: params[:phones_attributes].values
          })
        end
      end
    end
  end
end