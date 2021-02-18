# frozen_string_literal: true

module Entities
  module BenefitGroupAssignments
    # This class shows the list of required and optional attributes
    # that are required to build a new BenefitGroupAssignment object
    class BenefitGroupAssignment < Dry::Struct
      transform_keys(&:to_sym)

      attribute :benefit_package_id,  Types::Bson
      attribute :start_on,            Types::Date
      attribute :end_on,              Types::Date.optional.meta(omittable: true)
      attribute :hbx_enrollment_id,   Types::Bson.optional.meta(omittable: true)
      attribute :is_active,           Types::Bool.optional.meta(omittable: true)
      attribute :activated_at,        Types::DateTime.optional.meta(omittable: true)
    end
  end
end