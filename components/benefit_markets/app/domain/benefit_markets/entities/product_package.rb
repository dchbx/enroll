# frozen_string_literal: true

module BenefitMarkets
  module Entities
    class ProductPackage < Dry::Struct
      transform_keys(&:to_sym)

      attribute :application_period,           Types::Range
      attribute :benefit_kind,                 Types::Strict::Symbol
      attribute :product_kind,                 Types::Strict::Symbol
      attribute :package_kind,                 Types::Strict::Symbol
      attribute :title,                        Types::Strict::String
      attribute :description,                  Types::String.optional

      attribute :products,                     Types::Array.of(BenefitMarkets::Entities::Product).optional
      attribute :contribution_model,           BenefitMarkets::Entities::ContributionModel
      attribute :assigned_contribution_model,  BenefitMarkets::Entities::ContributionModel.optional
      attribute :contribution_models,          Types::Array.of(BenefitMarkets::Entities::ContributionModel).optional
      attribute :pricing_model,                BenefitMarkets::Entities::PricingModel

    end
  end
end