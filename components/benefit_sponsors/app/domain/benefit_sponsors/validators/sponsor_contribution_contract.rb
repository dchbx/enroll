# frozen_string_literal: true

module BenefitSponsors
  module Validators
    class SponsorContributionContract < Dry::Validation::Contract

      params do
        required(:contribution_levels).array(:hash)
      end

      rule(:contribution_levels).each do
        if key? && value
          result = ContributionLevelContract.call(value)
          key.failure(text: "invalid contribution level", error: result.errors.to_h) if result&.failure?
        end
      end
    end
  end
end