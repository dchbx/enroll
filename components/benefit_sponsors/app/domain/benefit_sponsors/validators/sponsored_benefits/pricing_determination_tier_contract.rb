# frozen_string_literal: true

module BenefitSponsors
  module Validators
    module SponsoredBenefits
      # This class checks and validates the incoming params
      # that are required to build a new pricing determination tier object
      # if any of the checks or rules fail it returns a failure
      class PricingDeterminationTierContract < Dry::Validation::Contract

        params do
          required(:pricing_unit_id).filled(Types::Bson)
          required(:price).filled(:float)
        end
      end
    end
  end
end
