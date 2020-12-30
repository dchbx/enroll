# frozen_string_literal: true

module BenefitMarkets
  module Entities
    class DentalProduct < BenefitMarkets::Entities::Product
      transform_keys(&:to_sym)

      attribute :hios_id,                       Types::Strict::String
      attribute :hios_base_id,                  Types::Strict::String
      attribute :csr_variant_id,                Types::String.optional
      attribute :dental_level,                  Types::Strict::Symbol
      attribute :dental_plan_kind,              Types::Strict::Symbol
      attribute :ehb,                           Types::Strict::Float
      attribute :is_standard_plan,              Types::Strict::Bool
      attribute :hsa_eligibility,               Types::Strict::Bool
      attribute :metal_level_kind,              Types::Strict::Symbol
    end
  end
end