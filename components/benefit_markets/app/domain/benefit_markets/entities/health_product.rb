# frozen_string_literal: true

module BenefitMarkets
  module Entities
    class HealthProduct < BenefitMarkets::Entities::Product
      transform_keys(&:to_sym)

      attribute :hios_id,                         Types::Strict::String
      attribute :hios_base_id,                    Types::Strict::String
      attribute :csr_variant_id,                  Types::String.optional.meta(omittable: true)
      attribute :health_plan_kind,                Types::Strict::Symbol
      attribute :metal_level_kind,                Types::Strict::Symbol
      attribute :ehb,                             Types::Strict::Float
      attribute :is_standard_plan,                Types::Strict::Bool
      attribute :rx_formulary_url,                Types::String.optional.meta(omittable: true)
      attribute :hsa_eligibility,                 Types::Strict::Bool
      attribute :provider_directory_url,          Types::String.optional.meta(omittable: true)
      attribute :network_information,             Types::String.optional.meta(omittable: true)
    end
  end
end