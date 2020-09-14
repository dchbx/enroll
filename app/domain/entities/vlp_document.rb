# frozen_string_literal: true

module Entities
  class VlpDocument < Dry::Struct
    transform_keys(&:to_sym)

    attribute :subject, Types::String.optional.meta(omittable: true)
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

  end
end