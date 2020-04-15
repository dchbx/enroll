# frozen_string_literal: true

require 'dry-struct'

module HbxEnrollments
  module Entities
    class HbxEnrollmentMembers < Dry::Struct

      transform_keys(&:to_sym)

      attribute :applicant_id,              Types::Bson
      attribute :carrier_member_id,         Types::Bson.optional.meta(omittable: true)
      attribute :is_subscriber,             Types::Strict::Bool
      attribute :premium_amount,            (HbxEnrollments::Entities::Curreny.default { HbxEnrollments::Entities::Curreny.new })
      attribute :applied_aptc_amount,       (HbxEnrollments::Entities::Curreny.default { HbxEnrollments::Entities::Curreny.new })
      attribute :eligibility_date,          Types::Nominal::DateTime
      attribute :coverage_start_on,         Types::Nominal::DateTime
      attribute :coverage_end_on,           Types::Nominal::DateTime.optional.meta(omittable: true)
    end
  end
end

