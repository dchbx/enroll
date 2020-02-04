# frozen_string_literal: true

module BenefitSponsors
  module Entities
    module Validators
      module SponsoredBenefits
        class PricingDeterminationTierContract < Dry::Validation::Contract

          params do
            required(:pricing_unit_id).filled(:string)
            required(:price).filled(:float)
          end
        end
      end
    end
  end
end