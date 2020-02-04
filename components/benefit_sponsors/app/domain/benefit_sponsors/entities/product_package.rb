# frozen_string_literal: true

module BenefitSponsors
  module Entities
    class ProductPackage < Dry::Struct
      transform_keys(&:to_sym)

      attribute :application_period,           Types::Duration
      attribute :benefit_kind,                 Types::Strict::Symbol
      attribute :product_kind,                 Types::Strict::Symbol
      attribute :package_kind,                 Types::Strict::Symbol
      attribute :title,                        Types::Strict::String
      attribute :description,                  Types::Strict::String

      attribute :products,                     Types::Product
      attribute :contribution_model,           Types::ContributionModel
      attribute :assigned_contribution_model,  Types::ContributionModel
      attribute :contribution_models,          Types::ContributionModel
      attribute :pricing_model,                Types::PricingModel

    end
  end
end