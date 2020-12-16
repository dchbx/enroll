# frozen_string_literal: true

module BenefitSponsors
  module Validators
    module SponsoredBenefits
      class DentalSponsoredBenefitContract < BenefitSponsors::Validators::SponsoredBenefits::SponsoredBenefitContract

        params do
          optional(:elected_product_choices).maybe(:array)
        end
      end
    end
  end
end
