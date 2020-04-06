# frozen_string_literal: true

module BenefitMarkets
  module Validators
    module ContributionModels
      class FixedDollarContributionUnitContract < BenefitMarkets::Validators::ContributionModels::ContributionUnitContract

        params do
          required(:default_contribution_amount).filled(:float)
        end

        rule(:default_contribution_amount) do
          if key? && value
            key.failure(text: "invalid default contribution amount for fixed dollar contribution unit", error: result.errors.to_h) unless value >= 0.0
          end
        end
      end
    end
  end
end