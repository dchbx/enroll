# frozen_string_literal: true

module BenefitMarkets
  module Validators
    module Products
      class ProductPackageContract < ::BenefitMarkets::Validators::ApplicationContract

        params do
          required(:package_kind).filled(:symbol)
          required(:application_period).value(type?: Range)
          required(:benefit_kind).filled(:symbol)
          required(:product_kind).filled(:symbol)
          required(:title).filled(:string)
          required(:contribution_models).value(:array)
          required(:pricing_model).filled(:hash)
          required(:products).value(:array)
          optional(:description).maybe(:string)
          required(:contribution_model).filled(:hash)
          optional(:assigned_contribution_model).filled(:hash)
        end

        rule(:contribution_model) do
          if key? && value
            result = BenefitMarkets::Validators::ContributionModels::ContributionModelContract.new.call(value)
            key.failure(text: "invalid contribution model", error: result.errors.to_h) if result&.failure?
          end
        end

        rule(:assigned_contribution_model) do
          if key? && value
            result = BenefitMarkets::Validators::ContributionModels::ContributionModelContract.new.call(value)
            key.failure(text: "invalid assigned contribution model", error: result.errors.to_h) if result&.failure?
          end
        end

        rule(:pricing_model) do
          if key? && value
            result = BenefitMarkets::Validators::PricingModels::PricingModelContract.new.call(value)
            key.failure(text: "invalid pricing model", error: result.errors.to_h) if result&.failure?
          end
        end
      end
    end
  end
end