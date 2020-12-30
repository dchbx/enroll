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
          required(:contribution_model).value(:any)
          required(:assigned_contribution_model).value(:any)
        end

        rule(:assigned_contribution_model) do
          if key? && value
            if !value.is_a?(::BenefitMarkets::Entities::ContributionModel)
              if value.is_a?(Hash)
                result = BenefitMarkets::Validators::ContributionModels::ContributionModelContract.new.call(value)
                key.failure(text: "invalid assigned contribution model", error: result.errors.to_h) if result&.failure?
              else
                key.failure(text: "invalid assigned contribution models. expected a hash or contribution_model entity")
              end
            end
          end
        end
      end
    end
  end
end