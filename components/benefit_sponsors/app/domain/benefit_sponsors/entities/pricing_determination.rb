# frozen_string_literal: true

module BenefitSponsors
  module Entities
    class PricingDetermination < Dry::Struct
      transform_keys(&:to_sym)

      attribute :group_size,                        Types::Strict::Integer
      attribute :participation_rate,                Types::Strict::Float

      attribute :pricing_determination_tiers,       Types::Array.of(BenefitSponsors::Entities::PricingDeterminationTier)
    end
  end
end