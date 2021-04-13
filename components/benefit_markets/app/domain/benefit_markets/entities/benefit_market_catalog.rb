# frozen_string_literal: true

module BenefitMarkets
  module Entities
    class BenefitMarketCatalog < Dry::Struct
      transform_keys(&:to_sym)

      attribute :application_interval_kind, Types::Strict::Symbol
      attribute :application_period, Types::Range
      attribute :probation_period_kinds, Types::Strict::Array
      attribute :title, Types::Strict::String
      attribute :description, Types::String.optional
      attribute :product_packages, Types::Array.of(BenefitMarkets::Entities::ProductPackage)

    end
  end
end