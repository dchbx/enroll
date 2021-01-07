# frozen_string_literal: true

module Entities
  class EmployerStaffRole < Dry::Struct
    transform_keys(&:to_sym)

    attribute :is_owner, Types::Bool
    attribute :benefit_sponsor_employer_profile_id, Types::Bson
    attribute :coverage_record, Entities::CoverageRecord
  end
end