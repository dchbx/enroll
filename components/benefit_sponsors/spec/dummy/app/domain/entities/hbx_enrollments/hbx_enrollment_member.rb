# frozen_string_literal: true

module Entities
  module HbxEnrollments
    # This class shows the list of required and optional attributes
    # that are required to build a new Enrollment member object
    class HbxEnrollmentMember < Dry::Struct
      transform_keys(&:to_sym)

      attribute :applicant_id,        Types::Bson
      attribute :carrier_member_id,   Types::Bson.optional.meta(omittable: true)
      attribute :is_subscriber,       Types::Strict::Bool
      attribute :premium_amount,      Types::Strict::Float.optional.meta(omittable: true)
      attribute :applied_aptc_amount, Types::Strict::Float.optional.meta(omittable: true)
      attribute :eligibility_date,    Types::Strict::Date
      attribute :coverage_start_on,   Types::Strict::Date
      attribute :coverage_end_on,     Types::Strict::Date.optional.meta(omittable: true)
    end
  end
end
