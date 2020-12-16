# frozen_string_literal: true

module BenefitSponsors
  module Entities
    class SponsoredBenefit < Dry::Struct
      transform_keys(&:to_sym)

      attribute :product_package_kind,        Types::Strict::Symbol
      attribute :product_option_choice,       Types::Strict::String
      attribute :source_kind,                 Types::Strict::Symbol

      attribute :reference_product_id,        Types::Bson
      attribute :sponsor_contribution,        BenefitSponsors::Entities::SponsorContribution
      attribute :pricing_determinations,      Types::Array.of(BenefitSponsors::Entities::PricingDetermination)

      attribute :product_kind,                Types::Symbol.optional.meta(omittable: true)
    end
  end
end
