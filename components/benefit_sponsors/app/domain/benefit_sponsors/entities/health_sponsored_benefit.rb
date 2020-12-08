# frozen_string_literal: true

module BenefitSponsors
  module Entities
    class HealthSponsoredBenefit < SponsoredBenefit
      transform_keys(&:to_sym)

    end
  end
end
