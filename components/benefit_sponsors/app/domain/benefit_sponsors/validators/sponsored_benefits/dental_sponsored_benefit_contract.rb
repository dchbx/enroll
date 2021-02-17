# frozen_string_literal: true

module BenefitSponsors
  module Validators
    module SponsoredBenefits
      # This class checks and validates the incoming params
      # that are required to build a new dental sponsored benefit object
      # if any of the checks or rules fail it returns a failure
      class DentalSponsoredBenefitContract < BenefitSponsors::Validators::SponsoredBenefits::SponsoredBenefitContract

        params do
          optional(:elected_product_choices).maybe(:array)
        end
      end
    end
  end
end
