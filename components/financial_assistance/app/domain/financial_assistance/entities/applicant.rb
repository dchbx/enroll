# frozen_string_literal: true

module FinancialAssistance
  module Entities
    class Applicant < Dry::Struct
      transform_keys(&:to_sym)

      attribute :name_pfx, Types::String.optional.meta(omittable: true)
      attribute :first_name, Types::String.optional
      attribute :middle_name, Types::String.optional.meta(omittable: true)
      attribute :last_name, Types::String.optional
      attribute :name_sfx, Types::String.optional.meta(omittable: true)
      attribute :ssn, Types::String.optional
      attribute :gender, Types::String.optional
      attribute :dob, Types::Date.optional
      attribute :is_primary_applicant, Types::Strict::Bool
      attribute :family_member_id, Types::Bson
      attribute :person_hbx_id, Types::String.optional
      attribute :is_incarcerated, Types::Strict::Bool
      attribute :is_disabled, Types::Strict::Bool.meta(omittable: true)
      attribute :ethnicity, Types::Strict::Array.meta(omittable: true)
      attribute :race, Types::String.optional.meta(omittable: true)
      attribute :indian_tribe_member, Types::Strict::Bool
      attribute :tribal_id, Types::String.optional.meta(omittable: true)

      attribute :language_code, Types::String.optional.meta(omittable: true)
      attribute :no_dc_address, Types::Strict::Bool.meta(omittable: true)
      attribute :is_homeless, Types::Strict::Bool.meta(omittable: true)
      attribute :is_temporarily_out_of_state, Types::Strict::Bool.meta(omittable: true)

      attribute :no_ssn, Types::String.optional.meta(omittable: true)
      attribute :citizen_status, Types::String.optional
      attribute :is_consumer_role, Types::Strict::Bool
      attribute :is_resident_role, Types::Strict::Bool.meta(omittable: true)
      attribute :vlp_document_id, Types::String.optional.meta(omittable: true)
      attribute :same_with_primary, Types::Strict::Bool
      attribute :is_applying_coverage, Types::Strict::Bool

      attribute :vlp_subject, Types::String.optional.meta(omittable: true)
      attribute :alien_number, Types::String.optional.meta(omittable: true)
      attribute :i94_number, Types::String.optional.meta(omittable: true)
      attribute :visa_number, Types::String.optional.meta(omittable: true)
      attribute :passport_number, Types::String.optional.meta(omittable: true)
      attribute :sevis_id, Types::String.optional.meta(omittable: true)
      attribute :naturalization_number, Types::String.optional.meta(omittable: true)
      attribute :receipt_number, Types::String.optional.meta(omittable: true)
      attribute :citizenship_number, Types::String.optional.meta(omittable: true)
      attribute :card_number, Types::String.optional.meta(omittable: true)
      attribute :country_of_citizenship, Types::String.optional.meta(omittable: true)
      attribute :expiration_date, Types::Date.optional.meta(omittable: true)
      attribute :issuing_country, Types::String.optional.meta(omittable: true)
      attribute :status, Types::String.optional.meta(omittable: true)

      attribute :addresses, Types::Array.of(FinancialAssistance::Entities::Address)
      attribute :emails, Types::Array.of(FinancialAssistance::Entities::Email)
      attribute :phones, Types::Array.of(FinancialAssistance::Entities::Phone)
    end
  end
end