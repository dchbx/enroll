# frozen_string_literal: true

module BenefitSponsors
  module Entities
    module Validators
      class PricingModels
        class PricingModelContract < Dry::Validation::Contract

          params do
            required(:name).filled(:string)
            required(:price_calculator_kind).filled(:string)
            required(:product_multiplicities).array(:symbol)
            required(:pricing_units).array(:hash)
            required(:member_relationships).array(:hash)
          end

          rule(:pricing_units).each do
            if key? && value
              result = PricingUnitContract.call(value)
              key.failure(text: "invalid pricing unit for pricing model", error: result.errors.to_h) if result&.failure?
            end
          end

          rule(:member_relationships).each do
            if key? && value
              result = MemberRelationshipContract.call(value)
              key.failure(text: "invalid member relationship for pricing model", error: result.errors.to_h) if result&.failure?
            end
          end
        end
      end
    end
  end
end