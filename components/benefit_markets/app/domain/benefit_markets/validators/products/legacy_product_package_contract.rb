# frozen_string_literal: true

# This contract is used to validate product packages in FEHB market only
module BenefitMarkets
  module Validators
    module Products
      class LegacyProductPackageContract < ::BenefitMarkets::Validators::ApplicationContract

        params do
          required(:package_kind).filled(:symbol)
          required(:application_period).value(type?: Range)
          required(:benefit_kind).filled(:symbol)
          required(:product_kind).filled(:symbol)
          required(:title).filled(:string)
          optional(:contribution_models).value(:array)
          required(:pricing_model).filled(:hash)
          required(:products).value(:array)
          optional(:description).maybe(:string)
          required(:contribution_model).value(:any)
          optional(:assigned_contribution_model).value(:any)
        end
      end
    end
  end
end