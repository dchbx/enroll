# frozen_string_literal: true

module BenefitMarkets
  module Validators
    module PricingModels
      class TieredPricingUnitContract < BenefitMarkets::Validators::PricingModels::PricingUnitContract

        params do
          required(:member_relationship_maps).array(:hash)
        end

        rule(:member_relationship_maps).each do
          if key? && value
            result = BenefitMarkets::Validators::PricingModels::MemberRelationshipMapContract.new.call(value)
            key.failure(text: "invalid member relationship maps for tiered pricing unit", error: result.errors.to_h) if result&.failure?
          end
        end
      end
    end
  end
end