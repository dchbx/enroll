# frozen_string_literal: true

module BenefitSponsors
  module Validators
    module SponsoredBenefits
      # This class checks and validates the incoming params
      # that are required to build a new health sponsored benefit object
      # if any of the checks or rules fail it returns a failure
      class HealthSponsoredBenefitContract < SponsoredBenefitContract

        params do
          # TODO: add params
        end
      end
    end
  end
end
