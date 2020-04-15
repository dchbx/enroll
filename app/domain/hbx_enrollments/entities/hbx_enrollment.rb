# frozen_string_literal: true

require 'dry-struct'

module HbxEnrollments
  module Entities
    class HbxEnrollment < Dry::Struct

      include Types

      transform_keys(&:to_sym)

      attribute :coverage_household_id,                           Types::Bson.optional.meta(omittable: true)
      attribute :kind,                                            Types::Strict::String
      attribute :enrollment_kind,                                 Types::Strict::String.default("open_enrollment")
      attribute :coverage_kind,                                   Types::Strict::String.default("health")
      attribute :changing,                                        Types::Strict::Bool.default(false)
      attribute :effective_on,                                    Types::Nominal::DateTime.optional.meta(omittable: true)
      attribute :terminated_on,                                   Types::Nominal::DateTime.optional.meta(omittable: true)
      attribute :terminate_reason,                                Types::Strict::String.optional.meta(omittable: true)
      attribute :broker_agency_profile_id,                        Types::Bson.optional.meta(omittable: true)
      attribute :hbx_id,                                          Types::Strict::String.optional.meta(omittable: true)
      attribute :special_enrollment_period_id,                    Types::Bson.optional.meta(omittable: true)
      attribute :predecessor_enrollment_id,                       Types::Bson.optional.meta(omittable: true)
      attribute :original_application_type,                       Types::Bson.optional.meta(omittable: true)
      attribute :submitted_at,                                    Types::Nominal::DateTime
      attribute :aasm_state,                                      Types::Strict::String.optional.meta(omittable: true)
      attribute :updated_by,                                      Types::Strict::String.optional.meta(omittable: true)
      attribute :is_active,                                       Types::Strict::Bool.default(true)
      attribute :waiver_reason,                                   Types::Strict::String.optional.meta(omittable: true)
      attribute :published_to_bus_at,                             Types::Strict::Date.optional.meta(omittable: true)
      attribute :review_status,                                   Types::Strict::String.default("incomplete")
      attribute :termination_submitted_on,                        Types::Strict::Date.optional.meta(omittable: true)
      attribute :checkbook_url,                                   Types::Strict::String.optional.meta(omittable: true)
      attribute :external_enrollment,                             Types::Strict::Bool.default(false)
      attribute :family_id,                                       Types::Bson
      attribute :household_id,                                    Types::Bson
      attribute :product_id,                                      Types::Bson
      attribute :issuer_profile_id,                               Types::Bson
      attribute :hbx_enrollment_members,                          Types::Strict::Array.of(Entities::HbxEnrollmentMembers)
    end
  end
end