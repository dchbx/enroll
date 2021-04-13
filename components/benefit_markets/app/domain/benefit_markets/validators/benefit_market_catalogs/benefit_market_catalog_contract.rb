# frozen_string_literal: true

module BenefitMarkets
  module Validators
    module BenefitMarketCatalogs
      class BenefitMarketCatalogContract < Dry::Validation::Contract

        params do
          required(:application_interval_kind).filled(:symbol)
          required(:application_period).filled(type?: Range)
          required(:probation_period_kinds).value(:array)
          required(:title).filled(:string)
          optional(:description).maybe(:string)
          required(:product_packages).value(:array)
        end

        rule(:product_packages).each do
          next unless key?
          next if value.blank? || value.is_a?(::BenefitMarkets::Entities::ProductPackage)
          if value.is_a?(Hash)
            result = BenefitMarkets::Validators::Products::LegacyProductPackageContract.new.call(value)
            key.failure(text: "invalid product package", error: result.errors.to_h) if result&.failure?
          else
            key.failure(text: "invalid product packages. expected a hash or product_package entity")
          end
        end
      end
    end
  end
end