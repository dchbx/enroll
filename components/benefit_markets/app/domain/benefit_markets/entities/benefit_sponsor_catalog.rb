# frozen_string_literal: true

module BenefitMarkets
  module Entities
    class BenefitSponsorCatalog < Dry::Struct
      transform_keys(&:to_sym)

      attribute :effective_date,          Types::Strict::Date
      attribute :effective_period,        Types::Range
      attribute :open_enrollment_period,  Types::Range
      attribute :probation_period_kinds,  Types::Strict::Array
      # attribute :benefit_application_id,  Types::String.optional
      attribute :product_packages,        Types::Array.of(BenefitMarkets::Entities::Products::ProductPackage)

    end
  end
end