# frozen_string_literal: true

module BenefitSponsors
  module Entities
    class BenefitSponsorCatalog < Dry::Struct
      transform_keys(&:to_sym)

      attribute :effective_date,          Types::Strict::Date
      attribute :effective_period,        Types::Duration
      attribute :open_enrollment_period,  Types::Duration
      attribute :probation_period_kinds,  Types::Strict::Array
      attribute :benefit_application_id,  Types::Strict::String
      attribute :product_packages,        Types::Array.of(Products::ProductPackage)

    end
  end
end