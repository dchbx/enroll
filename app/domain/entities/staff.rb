# frozen_string_literal: true

module Entities
  class Staff < Dry::Struct
    transform_keys(&:to_sym)

    attribute :first_name,           Types::String
    attribute :last_name,            Types::String
    attribute :dob,                  Types::Date.meta(omittable: true)
    attribute :email,                Types::String.optional.meta(omittable: true)
    attribute :area_code,            Types::String.optional.meta(omittable: true)
    attribute :number,               Types::String.optional.meta(omittable: true)
    # attribute :employee_coverage     Entities::EmployeeCoverage
  end
end
