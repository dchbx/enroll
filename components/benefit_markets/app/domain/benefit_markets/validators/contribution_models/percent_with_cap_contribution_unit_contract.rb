# frozen_string_literal: true

module BenefitMarkets
  module Validators
    module ContributionModels
      class PercentWithCapContributionUnitContract < BenefitMarkets::Validators::ContributionModels::ContributionUnitContract

        params do
          required(:default_contribution_factor).filled(:float)
          required(:default_contribution_cap).filled(:float)
          required(:minimum_contribution_factor).filled(:float)
        end

        rule(:default_contribution_factor) do
          if key? && value
            key.failure(text: "invalid default contribution amount for fixed dollar contribution unit", error: result.errors.to_h) unless value >= 0.0 && value <= 1.0
          end
        end

        rule(:default_contribution_cap) do
          if key? && value
            key.failure(text: "invalid default contribution amount for fixed dollar contribution unit", error: result.errors.to_h) unless value >= 0.00
          end
        end

        rule(:minimum_contribution_factor) do
          if key? && value
            key.failure(text: "invalid default contribution amount for fixed dollar contribution unit", error: result.errors.to_h) unless value >= 0.0 && value <= 1.0
          end
        end
      end
    end
  end
end