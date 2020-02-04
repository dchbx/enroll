# frozen_string_literal: true

module BenefitSponsors
  module Entities
    module PricingModels
      class PricingModel < Dry::Struct
        transform_keys(&:to_sym)

        attribute :name,    Types::Strict::String
        attribute :price_calculator_kind,        Types::Strict::String
        attribute :product_multiplicities,      Types::Strict::Array
        attribute :member_relationships,      Types::Array.of(PricingModels::MemberRelationship)
        attribute :pricing_units,      Types::Array.of(PricingModels::PricingUnit)

      end
    end
  end
end