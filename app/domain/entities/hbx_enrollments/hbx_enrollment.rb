# frozen_string_literal: true

module Entities
  module HbxEnrollments
    # This class shows the list of required and optional attributes
    # that are required to build a new Enrollment object
    class HbxEnrollment < Dry::Struct
      transform_keys(&:to_sym)

      # Common fields
      attribute :kind,                                 Types::Strict::String
      attribute :enrollment_kind,                      Types::Strict::String
      attribute :coverage_kind,                        Types::Strict::String
      attribute :effective_on,                         Types::Strict::Date

      attribute :coverage_household_id,                Types::Bson.optional.meta(omittable: true)
      attribute :changing,                             Types::Strict::Bool.optional.meta(omittable: true)
      attribute :terminated_on,                        Types::Strict::Date.optional.meta(omittable: true)
      attribute :terminate_reason,                     Types::Strict::String.optional.meta(omittable: true)
      attribute :broker_agency_profile_id,             Types::Bson.optional.meta(omittable: true)
      attribute :writing_agent_id,                     Types::Bson.optional.meta(omittable: true)
      attribute :hbx_id,                               Types::Strict::String.optional.meta(omittable: true)
      attribute :special_enrollment_period_id,         Types::Bson.optional.meta(omittable: true)
      attribute :predecessor_enrollment_id,            Types::Bson.optional.meta(omittable: true)
      attribute :enrollment_signature,                 Types::Strict::String.optional.meta(omittable: true)
      attribute :plan_id,                              Types::Bson.optional.meta(omittable: true)
      attribute :carrier_profile_id,                   Types::Bson.optional.meta(omittable: true)
      attribute :product_id,                           Types::Bson.optional.meta(omittable: true)
      attribute :issuer_profile_id,                    Types::Bson.optional.meta(omittable: true)
      attribute :original_application_type,            Types::Strict::String.optional.meta(omittable: true)
      attribute :submitted_at,                         Types::Strict::DateTime.optional.meta(omittable: true)
      attribute :aasm_state,                           Types::Strict::String.optional.meta(omittable: true)
      attribute :aasm_state_date,                      Types::Strict::Date.optional.meta(omittable: true)
      attribute :updated_by,                           Types::Strict::String.optional.meta(omittable: true)
      attribute :is_active,                            Types::Strict::Bool.optional.meta(omittable: true)
      attribute :waiver_reason,                        Types::Strict::String.optional.meta(omittable: true)
      attribute :published_to_bus_at,                  Types::Strict::DateTime.optional.meta(omittable: true)
      attribute :review_status,                        Types::Strict::String.optional.meta(omittable: true)
      attribute :special_verification_period,          Types::Strict::DateTime.optional.meta(omittable: true)
      attribute :termination_submitted_on,             Types::Strict::DateTime.optional.meta(omittable: true)
      attribute :checkbook_url,                        Types::Strict::String.optional.meta(omittable: true)
      attribute :external_enrollment,                  Types::Strict::Bool.optional.meta(omittable: true)
      # IVL fields.
      attribute :is_any_enrollment_member_outstanding, Types::Bool.optional.meta(omittable: true)
      attribute :elected_aptc_pct,                     Types::Strict::Float.optional.meta(omittable: true)
      attribute :applied_aptc_amount,                  Types::Strict::Float.optional.meta(omittable: true)
      attribute :consumer_role_id,                     Types::Bson.optional.meta(omittable: true)
      attribute :resident_role_id,                     Types::Bson.optional.meta(omittable: true)
      # SHOP fields
      attribute :employee_role_id,                     Types::Bson.optional.meta(omittable: true)
      attribute :benefit_group_id,                     Types::Bson.optional.meta(omittable: true)
      attribute :benefit_group_assignment_id,          Types::Bson.optional.meta(omittable: true)
      attribute :benefit_package_id,                   Types::Bson.optional.meta(omittable: true)
      attribute :benefit_coverage_period_id,           Types::Bson.optional.meta(omittable: true)
      attribute :benefit_sponsorship_id,               Types::Bson.optional.meta(omittable: true)
      attribute :sponsored_benefit_package_id,         Types::Bson.optional.meta(omittable: true)
      attribute :sponsored_benefit_id,                 Types::Bson.optional.meta(omittable: true)
      attribute :rating_area_id,                       Types::Bson.optional.meta(omittable: true)
      # Depricated Fields.
      attribute :elected_amount,                       Types::Float.optional.meta(omittable: true)
      attribute :elected_premium_credit,               Types::Float.optional.meta(omittable: true)
      attribute :applied_premium_credit,               Types::Float.optional.meta(omittable: true)

      attribute :hbx_enrollment_members,               Types::Array.of(Entities::HbxEnrollments::HbxEnrollmentMember)

      attribute :family_id,                            Types::Bson.optional.meta(omittable: true)
      attribute :household_id,                         Types::Bson.optional.meta(omittable: true)
    end
  end
end
