# frozen_string_literal: true

module BenefitMarkets
  module Entities
    module Products
      class Product < Dry::Struct
        transform_keys(&:to_sym)

        attribute :benefit_market_kind,   Types::Strict::Symbol
        attribute :application_period,    Types::DateRange
        attribute :hbx_id,                Types::Strict::String
        attribute :title,                 Types::Strict::String
        attribute :description,           Types::Strict::String
        attribute :issuer_profile_id,     Types::Strict::String
        attribute :product_package_kinds, Types::Strict::Array
        attribute :kind,                  Types::Strict::Symbol
        attribute :premium_ages,          Types::Range
        attribute :provider_directory_url,      Types::Strict::String
        attribute :is_reference_plan_eligible,  Types::Strict::Bool
        attribute :deductible, Types::Strict::String
        attribute :family_deductible, Types::Strict::String
        attribute :issuer_assigned_id, Types::Strict::String
        attribute :service_area_id, Types::Strict::String
        attribute :network_information, Types::Strict::String
        attribute :nationwide, Types::Strict::Bool
        attribute :dc_in_network, Types::Strict::Bool

        attribute :sbc_document,   Document
        attribute :premium_tables, Types::Array.of(PremiumTable)
      end
    end
  end
end