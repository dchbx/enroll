# frozen_string_literal: true

module BenefitSponsors
  module Validators
    module Profiles
      # Profile Contract is to validate submitted params while persisting agency profile
      class AcaShopDcEmployerProfileContract < ProfileContract
        params do
          required(:is_benefit_sponsorship_eligible).filled(:bool)
        end

        rule(:is_benefit_sponsorship_eligible) do
          if key?
            key.failure("Benefit Sponsorship should be true") unless value
          end
        end
      end
    end
  end
end
