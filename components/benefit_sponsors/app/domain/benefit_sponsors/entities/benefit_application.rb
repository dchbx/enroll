# frozen_string_literal: true

module BenefitSponsors
  module Entities
    class BenefitApplication < Dry::Struct
      transform_keys(&:to_sym)

      attribute :expiration_date,             Types::Strict::Date
      attribute :effective_period,            Types::Range
      attribute :open_enrollment_period,      Types::Range
      attribute :terminated_on,               Types::Date.optional
      attribute :aasm_state,                  Types::Strict::Symbol
      attribute :fte_count,                   Types::Strict::Integer
      attribute :pte_count,                   Types::Strict::Integer
      attribute :msp_count,                   Types::Strict::Integer
      attribute :recorded_sic_code,           Types::String.optional
      attribute :predecessor_id,              Types::Bson.optional
      attribute :recorded_rating_area_id,     Types::Bson
      attribute :recorded_service_area_ids,   Types::Strict::Array
      attribute :benefit_sponsor_catalog_id,  Types::Bson
      attribute :termination_kind,            Types::String.optional
      attribute :termination_reason,          Types::String.optional

    end
  end
end