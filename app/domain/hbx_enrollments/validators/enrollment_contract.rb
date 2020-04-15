# frozen_string_literal: true

module HbxEnrollments
  module Validators
    class EnrollmentContract < Dry::Validation::Contract
      params do
        optional(:coverage_household_id).filled(type?: BSON::ObjectId)
        required(:kind).filled(:string)
        required(:enrollment_kind).filled(:string)
        required(:coverage_kind).filled(:string)
        optional(:changing).filled(:bool)
        required(:effective_on).filled(type?: Date)
        optional(:broker_agency_profile_id).filled(:string)
        optional(:hbx_id).maybe(:string, :filled?)
        optional(:special_enrollment_period_id).filled(type?: BSON::ObjectId)
        optional(:predecessor_enrollment_id).filled(type?: BSON::ObjectId)
        optional(:original_application_type).filled(:string)
        required(:submitted_at).filled(type?: Date)
        optional(:aasm_state).maybe(:string, :filled?)
        optional(:updated_by).filled(:string)
        required(:is_active).filled(:bool)
        optional(:waiver_reason).filled(:string)
        optional(:published_to_bus_at).filled(:date)
        optional(:review_status).filled(:string)
        optional(:checkbook_url).filled(:string)
        optional(:external_enrollment).filled(:bool)
        required(:family_id).filled(type?: BSON::ObjectId)
        optional(:household_id).filled(type?: BSON::ObjectId)
        required(:product_id).filled(type?: BSON::ObjectId)
        required(:issuer_profile_id).filled(type?: BSON::ObjectId)
        optional(:plan_id).value(type?: BSON::ObjectId)
        optional(:carrier_profile_id).value(type?: BSON::ObjectId)
        optional(:hbx_enrollment_members).array(:hash) do
          required(:applicant_id).filled(type?: BSON::ObjectId)
          optional(:carrier_member_id).filled(type?: BSON::ObjectId)
          required(:is_subscriber).filled(:bool)
          # optional(:premium_amount).filled(:string)
          optional(:premium_amount).hash do
            optional(:cents).maybe(:float, :filled?)
            optional(:currency_iso).maybe(:string, :filled?)
          end
          optional(:applied_aptc_amount).hash do
            optional(:cents).maybe(:float, :filled?)
            optional(:currency_iso).maybe(:string, :filled?)
          end
          required(:eligibility_date).value(type?: Date)
          required(:coverage_start_on).filled(:date)
          optional(:coverage_end_on).value(type?: Date)
        end
      end
    end
  end
end
