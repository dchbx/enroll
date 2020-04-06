# frozen_string_literal: true

module BenefitMarkets
  module Entities
    class RelationshipPricingUnit < BenefitMarkets::Entities::PricingUnit
      transform_keys(&:to_sym)

      attribute :discounted_above_threshold,             Types::Strict::Integer
      attribute :eligible_for_threshold_discount,        Types::Strict::Bool

    end
  end
end