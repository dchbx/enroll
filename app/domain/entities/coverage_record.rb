# frozen_string_literal: true

module Entities
  class CoverageRecord < Dry::Struct
    transform_keys(&:to_sym)

    attribute :ssn, Types::String.optional
    attribute :dob, Types::Date.optional
    attribute :hired_on, Types::Date.optional
    attribute :gender, Types::String.optional
    attribute :is_applying_coverage, Types::Bool
    attribute :address, Entities::Address.optional
    attribute :email, Entities::Email.optional
  end
end