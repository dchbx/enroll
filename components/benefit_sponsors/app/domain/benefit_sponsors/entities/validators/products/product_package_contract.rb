# frozen_string_literal: true

module BenefitSponsors
  module Entities
    module Validators
      module Products
        class ProductPackageContract < ApplicationContract

          params do
            required(:application_period).value(Types::Duration)
            required(:benefit_kind).filled(:symbol)
            required(:product_kind).filled(:symbol)
            required(:package_kind).filled(:symbol)
            required(:title).filled(:string)
            optional(:description).maybe(:string)
            required(:products).array(:hash)
            required(:contribution_model).filled(:hash)
            required(:assigned_contribution_model).filled(:hash)
            required(:contribution_models).array(:hash)
            required(:pricing_model).filled(:hash)
          end

          rule(:products).each do
            if key? && value
              result = ProductContract.call(value)
              key.failure(text: "invalid product", error: result.errors.to_h) if result&.failure?
            end
          end

          rule(:contribution_model) do
            if key? && value
              result = ContributionModels::ContributionModelContract.call(value)
              key.failure(text: "invalid contribution model", error: result.errors.to_h) if result&.failure?
            end
          end

          rule(:assigned_contribution_model) do
            if key? && value
              result = ContributionModels::ContributionModelContract.call(value)
              key.failure(text: "invalid assigned contribution model", error: result.errors.to_h) if result&.failure?
            end
          end

          rule(:contribution_models).each do
            if key? && value
              result = ContributionModels::ContributionModelContract.call(value)
              key.failure(text: "invalid contribution model", error: result.errors.to_h) if result&.failure?
            end
          end

          rule(:pricing_model) do
            if key? && value
              result = PricingModels::PricingModelContract.call(value)
              key.failure(text: "invalid pricing model", error: result.errors.to_h) if result&.failure?
            end
          end
        end
      end
    end
  end
end