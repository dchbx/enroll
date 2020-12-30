# frozen_string_literal: true

module BenefitSponsors
  module Entities
    class SponsorContribution < Dry::Struct
      transform_keys(&:to_sym)

      attribute :contribution_levels, Types::Array.of(BenefitSponsors::Entities::ContributionLevel)
    end
  end
end