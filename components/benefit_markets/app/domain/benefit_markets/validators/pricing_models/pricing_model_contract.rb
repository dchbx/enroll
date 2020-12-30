# frozen_string_literal: true

module BenefitMarkets
  module Validators
    module PricingModels
      class PricingModelContract < Dry::Validation::Contract

        params do
          required(:_id).filled(Types::Bson)
          required(:name).filled(:string)
          required(:price_calculator_kind).filled(:string)
          required(:product_multiplicities).array(:symbol)
          required(:pricing_units).value(:array)
          required(:member_relationships).array(:hash)
        end

        rule(:pricing_units).each do
          if key? && value
            if ![::BenefitMarkets::Entities::PricingUnit, ::BenefitMarkets::Entities::RelationshipPricingUnit,  ::BenefitMarkets::Entities::TieredPricingUnit].include?(value.class)
              if value.is_a?(Hash)
                result = ::BenefitMarkets::Validators::PricingModels::PricingUnitContract.new.call(value)
                key.failure(text: "invalid pricing unit for pricing model", error: result.errors.to_h) if result&.failure?
              else
                key.failure(text: "invalid pricing unit. Expected an hash or pricing unit entity")
              end
            end
          end
        end

        rule(:member_relationships).each do
          if key? && value
            result = BenefitMarkets::Validators::PricingModels::MemberRelationshipContract.new.call(value)
            key.failure(text: "invalid member relationship for pricing model", error: result.errors.to_h) if result&.failure?
          end
        end
      end
    end
  end
end