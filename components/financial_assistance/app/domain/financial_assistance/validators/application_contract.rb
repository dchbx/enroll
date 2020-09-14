# frozen_string_literal: true

module FinancialAssistance
  module Validators
    class ApplicationContract < Dry::Validation::Contract

      params do
        required(:family_id).filled(:string)
        required(:assistance_year).filled(:integer)
        optional(:years_to_renew).maybe(:integer)
        optional(:renewal_consent_through_year).maybe(:integer)
        required(:benchmark_product_id).filled(:string)
        optional(:is_ridp_verified).maybe(:bool)
        required(:applicants).array(:hash)
      end

      rule(:years_to_renew, :renewal_consent_through_year) do
        key.failure('at least one must be provided') unless values[:years_to_renew] || values[:renewal_consent_through_year]
      end

      rule(:family_id) do
        if key? && value
          result = Operations::Families::Find.new.call(value)
          key.failure(text: 'invalid family_id', error: result.errors.to_h) if result&.failure?
        end
      end
    end
  end
end
