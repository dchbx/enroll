# frozen_string_literal: true

module BenefitSponsors
  module Entities
    # This class shows the list of required and optional attributes
    # that are required to build a new health sponsored benefit object
    class HealthSponsoredBenefit < SponsoredBenefit
      transform_keys(&:to_sym)

    end
  end
end
