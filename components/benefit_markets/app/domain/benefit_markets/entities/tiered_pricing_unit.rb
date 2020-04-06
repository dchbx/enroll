# frozen_string_literal: true

module BenefitMarkets
  module Entities
    class TieredPricingUnit < BenefitMarkets::Entities::PricingUnit
      transform_keys(&:to_sym)

      attribute :member_relationship_maps,  Types::Array.of(BenefitMarkets::Entities::MemberRelationshipMap)

    end
  end
end