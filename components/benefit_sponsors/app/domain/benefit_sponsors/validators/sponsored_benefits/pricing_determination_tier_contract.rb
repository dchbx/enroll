# frozen_string_literal: true

module BenefitSponsors
  module Validators
    module SponsoredBenefits
      class PricingDeterminationTierContract < Dry::Validation::Contract

        params do
          required(:pricing_unit_id).filled(Types::Bson)
          required(:price).filled(:float)
        end
      end
    end
  end
end
