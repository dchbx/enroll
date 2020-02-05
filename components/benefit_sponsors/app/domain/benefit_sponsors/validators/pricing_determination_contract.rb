# frozen_string_literal: true

module BenefitSponsors
  module Validators
    class PricingDeterminationContract < Dry::Validation::Contract

      params do
        required(:group_size).filled(:integer)
        required(:participation_rate).filled(:float)
        required(:pricing_determination_tiers).array(:hash)
      end

      rule(:pricing_determination_tiers).each do
        if key? && value
          result = PricingDeterminationTierContract.call(value)
          key.failure(text: "invalid pricing determination tier", error: result.errors.to_h) if result&.failure?
        end
      end
    end
  end
end