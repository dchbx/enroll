# frozen_string_literal: true

module BenefitMarkets
  module Entities
    class ProductPackage < Dry::Struct
      transform_keys(&:to_sym)

      attribute :application_period,           Types::CustomRange
      attribute :benefit_kind,                 Types::Strict::Symbol
      attribute :product_kind,                 Types::Strict::Symbol
      attribute :package_kind,                 Types::Strict::Symbol
      attribute :title,                        Types::Strict::String
      attribute :description,                  Types::String.meta(omittable: true)

      attribute :products,                     Types::Array.of(Product)
      attribute :contribution_model,           BenefitMarkets::Entities::ContributionModel
      attribute :assigned_contribution_model,  BenefitMarkets::Entities::ContributionModel.meta(omittable: true)
      attribute :contribution_models,          Types::Array.of(BenefitMarkets::Entities::ContributionModel)
      attribute :pricing_model,                BenefitMarkets::Entities::PricingModel

    end
  end
end