# frozen_string_literal: true

module BenefitSponsors
  module Entities
    module SponsoredBenefits
      class SponsoredBenefit < Dry::Struct
        transform_keys(&:to_sym)

        attribute :product_package_kind, Types::Strict::Symbol
        attribute :product_option_choice, Types::Strict::String
        attribute :source_kind, Types::Strict::Symbol

        attribute :reference_product, Products::Product
        attribute :sponsor_contribution, SponsoredBenefits::SponsorContribution
        attribute :pricing_determinations, Types::Array.of(SponsoredBenefits::PricingDetermination)
      end
    end
  end
end