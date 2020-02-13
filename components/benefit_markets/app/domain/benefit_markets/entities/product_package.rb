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
      attribute :description,                  Types::Strict::String

      attribute :products,                     Types::Array.of(Product)
      attribute :contribution_model,           ContributionModel
      attribute :assigned_contribution_model,  ContributionModel.meta(omittable: true)
      attribute :contribution_models,          Types::Array.of(ContributionModel)
      attribute :pricing_model,                PricingModel

    end
  end
end