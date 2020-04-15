# frozen_string_literal: true

module HbxEnrollments
  module Validators
    class IvlContract < EnrollmentContract
      params do
        optional(:enrollment_signature).maybe(:string, :filled?)
        required(:consumer_role_id).filled(type?: BSON::ObjectId)
        optional(:resident_role_id).filled(type?: BSON::ObjectId)
        optional(:is_any_enrollment_member_outstanding).filled(:bool)
        optional(:elected_amount).hash do
          optional(:cents).filled(:float)
          optional(:currency_iso).filled(:string)
        end
        optional(:elected_premium_credit).hash do
          optional(:cents).filled(:float)
          optional(:currency_iso).filled(:string)
        end
        optional(:applied_premium_credit).hash do
          optional(:cents).filled(:float)
          optional(:currency_iso).filled(:string)
        end
        optional(:elected_aptc_pct).filled(:float)
        optional(:applied_aptc_amount).hash do
          optional(:cents).filled(:float)
          optional(:currency_iso).filled(:string)
        end
        optional(:benefit_coverage_period_id).filled(type?: BSON::ObjectId)
        optional(:benefit_package_id).filled(type?: BSON::ObjectId)
        optional(:special_verification_period).maybe(:date, :filled?)
      end

      rule do
        key.failure('missing role') if values[:consumer_role_id].blank? && values[:resident_role_id].blank?
      end

    end
  end
end