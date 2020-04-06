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
      attribute :description,                  Types::String.optional.meta(omittable: true)

      attribute :products,                     Types::Array.of(BenefitMarkets::Entities::Product).meta(omittable: false)
      attribute :contribution_model,           BenefitMarkets::Entities::ContributionModel
      attribute :assigned_contribution_model,  BenefitMarkets::Entities::ContributionModel
      attribute :contribution_models,          Types::Array.of(BenefitMarkets::Entities::ContributionModel).meta(omittable: false)
      attribute :pricing_model,                BenefitMarkets::Entities::PricingModel

    end
  end
end