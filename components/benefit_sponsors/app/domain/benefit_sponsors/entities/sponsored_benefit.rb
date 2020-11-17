# frozen_string_literal: true

module BenefitSponsors
  module Entities
    class SponsoredBenefit < Dry::Struct
      transform_keys(&:to_sym)

      attribute :product_package_kind,        Types::Strict::Symbol
      attribute :product_option_choice,       Types::Strict::String
      attribute :source_kind,                 Types::Strict::Symbol

      attribute :reference_product,           ::BenefitMarkets::Entities::Product
      attribute :sponsor_contribution,        BenefitSponsors::Entities::SponsorContribution
      attribute :pricing_determinations,      Types::Array.of(BenefitSponsors::Entities::PricingDetermination)

      attribute :_type,                       Types::Strict::String.optional.meta(omittable: true)
    end
  end
end
