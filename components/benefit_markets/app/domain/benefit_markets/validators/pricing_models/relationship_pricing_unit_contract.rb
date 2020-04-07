# frozen_string_literal: true

module BenefitMarkets
  module Validators
    module PricingModels
      class RelationshipPricingUnitContract < BenefitMarkets::Validators::PricingModels::PricingUnitContract

        params do
          optional(:discounted_above_threshold).maybe(:integer)
          required(:eligible_for_threshold_discount).filled(:bool)
        end

        rule(:discounted_above_threshold) do
          if key? && value
            key.failure(text: "invalid discount threshold for relationship pricing unit", error: result.errors.to_h) unless value >= 0
          end
        end
      end
    end
  end
end