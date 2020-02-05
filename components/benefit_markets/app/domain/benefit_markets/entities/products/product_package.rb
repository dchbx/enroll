# frozen_string_literal: true

module BenefitMarkets
  module Entities
    module Products
      class ProductPackage < Dry::Struct
        transform_keys(&:to_sym)

        attribute :application_period,           Types::Duration
        attribute :benefit_kind,                 Types::Strict::Symbol
        attribute :product_kind,                 Types::Strict::Symbol
        attribute :package_kind,                 Types::Strict::Symbol
        attribute :title,                        Types::Strict::String
        attribute :description,                  Types::Strict::String

        attribute :products,                     Types::Array.of(Products::Product)
        attribute :contribution_model,           ContributionModels::ContributionModel
        attribute :assigned_contribution_model,  ContributionModels::ContributionModel
        attribute :contribution_models,          Types::Array.of(ContributionModels::ContributionModel)
        attribute :pricing_model,                PricingModels::PricingModel

      end
    end
  end
end