# frozen_string_literal: true

require 'dry-struct'

module HbxEnrollments
  module Entities
    class IvlEnrollment < ::HbxEnrollments::Entities::HbxEnrollment

      attribute :is_any_enrollment_member_outstanding,            Types::Strict::Bool.default(false)
      attribute :elected_amount,                                  (HbxEnrollments::Entities::Curreny.default { HbxEnrollments::Entities::Curreny.new })
      attribute :elected_premium_credit,                          (HbxEnrollments::Entities::Curreny.default { HbxEnrollments::Entities::Curreny.new })
      attribute :applied_premium_credit,                          (HbxEnrollments::Entities::Curreny.default { HbxEnrollments::Entities::Curreny.new })
      attribute :applied_aptc_amount,                             (HbxEnrollments::Entities::Curreny.default { HbxEnrollments::Entities::Curreny.new })
      attribute :elected_aptc_pct,                                Types::Strict::Float.default(0.0)
      attribute :enrollment_signature,                            Types::Strict::String.optional.meta(omittable: true)
      attribute :consumer_role_id,                                Types::Bson
      attribute :resident_role_id,                                Types::Bson.optional.meta(omittable: true)
      attribute :plan_id,                                         Types::Bson.optional.meta(omittable: true)
      attribute :carrier_profile_id,                              Types::Bson.optional.meta(omittable: true)
      attribute :benefit_coverage_period_id,                      Types::Bson.optional.meta(omittable: true)
      attribute :benefit_package_id,                              Types::Bson.optional.meta(omittable: true)
      attribute :special_verification_period,                     Types::Strict::Date.optional.meta(omittable: true)
    end
  end
end
