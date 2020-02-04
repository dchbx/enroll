# frozen_string_literal: true

module BenefitSponsors
  module Entities
    module BenefitApplications
      class BenefitApplication < Dry::Struct
        transform_keys(&:to_sym)

        attribute :expiration_date,             Types::Strict::Date
        attribute :effective_period,            Types::Duration
        attribute :open_enrollment_period,      Types::Duration
        attribute :terminated_on,               Types::Strict::Date
        attribute :aasm_state,                  Types::Strict::Symbol
        attribute :fte_count,                   Types::Strict::Integer
        attribute :pte_count,                   Types::Strict::Integer
        attribute :msp_count,                   Types::Strict::Integer
        attribute :recorded_sic_code,           Types::Strict::String
        attribute :predecessor_id,              Types::Strict::String
        attribute :recorded_rating_area_id,     Types::Strict::String
        attribute :recorded_service_area_ids,   Types::Strict::Array
        attribute :benefit_sponsor_catalog_id,  Types::Strict::String
        attribute :termination_kind,            Types::Strict::String
        attribute :termination_reason,          Types::Strict::String
        attribute :benefit_packages,            BenefitPackages::BenefitPackage

      end
    end
  end
end