# frozen_string_literal: true

module BenefitSponsors
  module Entities
    class BenefitSponsorship < Dry::Struct
      transform_keys(&:to_sym)

      attribute :_id,                     Types::Bson
      attribute :hbx_id,                  Types::Strict::String
      attribute :profile_id,              Types::Bson
      attribute :effective_begin_on,      Types::Date.optional
      attribute :effective_end_on,        Types::Date.optional
      attribute :termination_kind,        Types::String.optional
      attribute :termination_reason,      Types::String.optional
      attribute :predecessor_id,          Types::Bson.optional
      attribute :source_kind,             Types::Strict::Symbol
      attribute :registered_on,           Types::Strict::Date
      attribute :is_no_ssn_enabled,       Types::Strict::Bool
      attribute :ssn_enabled_on,          Types::Date.optional
      attribute :ssn_disabled_on,         Types::Date.optional
      attribute :aasm_state,              Types::Strict::Symbol
      attribute :organization_id,         Types::Bson

      attribute :benefit_applications,    Types::Array.of(BenefitSponsors::Entities::BenefitApplication)

    end
  end
end