# frozen_string_literal: true

module Entities
  class Person < Dry::Struct
    transform_keys(&:to_sym)

    attribute :hbx_id, Types::String.optional.meta(omittable: true)
    attribute :name_pfx, Types::String.optional.meta(omittable: true)
    attribute :first_name, Types::String.optional
    attribute :middle_name, Types::String.optional.meta(omittable: true)
    attribute :last_name, Types::String.optional
    attribute :name_sfx, Types::String.optional.meta(omittable: true)
    attribute :ssn, Types::String.optional.meta(omittable: true)
    attribute :gender, Types::String.optional
    attribute :dob, Types::Date.optional

    attribute :is_incarcerated, Types::Bool.optional.meta(omittable: true)
    attribute :is_disabled, Types::Strict::Bool.meta(omittable: true)
    attribute :ethnicity, Types::Array.optional.meta(omittable: true)
    attribute :race, Types::String.optional.meta(omittable: true)
    attribute :tribal_id, Types::String.optional.meta(omittable: true)

    attribute :language_code, Types::String.optional.meta(omittable: true)
    attribute :no_dc_address, Types::Strict::Bool.meta(omittable: true)
    attribute :is_homeless, Types::Strict::Bool.meta(omittable: true)
    attribute :is_temporarily_out_of_state, Types::Strict::Bool.meta(omittable: true)

    attribute :no_ssn, Types::String.optional.meta(omittable: true)

    attribute :addresses, Types::Array.of(Entities::Address)
    attribute :emails, Types::Array.of(Entities::Email)
    attribute :phones, Types::Array.of(Entities::Phone)
  end
end
