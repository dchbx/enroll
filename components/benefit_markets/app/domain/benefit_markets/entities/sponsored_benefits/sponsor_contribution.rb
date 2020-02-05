# frozen_string_literal: true

module BenefitMarkets
  module Entities
    module SponsoredBenefits
      class SponsorContribution < Dry::Struct
        transform_keys(&:to_sym)

        attribute :contribution_levels, Types::Array.of(SponsoredBenefits::ContributionLevels)
      end
    end
  end
end