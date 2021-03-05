# frozen_string_literal: true

module Validators
  module HbxEnrollments
    # This class checks and validates the incoming params
    # that are required to build a new Enrollment object,
    # if any of the checks or rules fail it returns a failure
    class HbxEnrollmentContract < Dry::Validation::Contract

      params do
        required(:kind).filled(:string)
        required(:enrollment_kind).filled(:string)
        required(:coverage_kind).filled(:string)
        required(:effective_on).filled(:date)

        optional(:coverage_household_id).maybe(Types::Bson)
        optional(:changing).maybe(:bool)
        optional(:terminated_on).maybe(:date)
        optional(:terminate_reason).maybe(:string)
        optional(:broker_agency_profile_id).maybe(Types::Bson)
        optional(:writing_agent_id).maybe(Types::Bson)
        optional(:hbx_id).maybe(:string)
        optional(:special_enrollment_period_id).maybe(Types::Bson)
        optional(:predecessor_enrollment_id).maybe(Types::Bson)
        optional(:enrollment_signature).maybe(:string)
        optional(:plan_id).maybe(Types::Bson)
        optional(:carrier_profile_id).maybe(Types::Bson)
        optional(:product_id).maybe(Types::Bson)
        optional(:issuer_profile_id).maybe(Types::Bson)
        optional(:original_application_type).maybe(:string)
        optional(:submitted_at).maybe(:date_time)
        optional(:aasm_state).maybe(:string)
        optional(:aasm_state_date).maybe(:date)
        optional(:updated_by).maybe(:string)
        optional(:is_active).maybe(:bool)
        optional(:waiver_reason).maybe(:string)
        optional(:published_to_bus_at).maybe(:date_time)
        optional(:review_status).maybe(:string)
        optional(:special_verification_period).maybe(:date_time)
        optional(:termination_submitted_on).maybe(:date_time)
        optional(:checkbook_url).maybe(:string)
        optional(:external_enrollment).maybe(:bool)
        # IVL fields
        optional(:is_any_enrollment_member_outstanding).maybe(:bool)
        optional(:elected_aptc_pct).maybe(:float)
        optional(:applied_aptc_amount).maybe(:float)
        optional(:consumer_role_id).maybe(Types::Bson)

        # Coverall fields
        optional(:resident_role_id).maybe(Types::Bson)

        # SHOP fields
        optional(:employee_role_id).maybe(Types::Bson)
        optional(:benefit_group_id).maybe(Types::Bson)
        optional(:benefit_group_assignment_id).maybe(Types::Bson)
        optional(:benefit_package_id).maybe(Types::Bson)
        optional(:benefit_coverage_period_id).maybe(Types::Bson)
        optional(:benefit_sponsorship_id).maybe(Types::Bson)
        optional(:sponsored_benefit_package_id).maybe(Types::Bson)
        optional(:sponsored_benefit_id).maybe(Types::Bson)
        optional(:rating_area_id).maybe(Types::Bson)

        optional(:elected_amount).maybe(:float)
        optional(:elected_premium_credit).maybe(:float)
        optional(:applied_premium_credit).maybe(:float)

        optional(:hbx_enrollment_members).array(:hash)

        optional(:family_id).maybe(Types::Bson)
        optional(:household_id).maybe(Types::Bson)
      end

      rule(:terminated_on, :effective_on) do
        if key? && value
          if !value.is_a?(Date)
            key.failure('must be a date')
          elsif values[:terminated_on] < values[:effective_on]
            key.failure('must be on or after effective_on.')
          end
        end
      end

      rule(:hbx_enrollment_members) do
        if key? && value
          hbx_enrollment_members_array = value.inject([]) do |hash_array, member_hash|
            if member_hash.is_a?(Hash)
              result = HbxEnrollmentMemberContract.new.call(member_hash)
              if result&.failure?
                key.failure(text: 'invalid hbx_enrollment_member', error: result.errors.to_h)
              else
                hash_array << result.to_h
              end
            else
              key.failure(text: 'invalid hbx_enrollment_member. Expected a hash.')
            end
            hash_array
          end
          values.merge!(hbx_enrollment_members: hbx_enrollment_members_array)
        end
      end

      rule(:kind) do
        # Write rules based on market
        if key? && value
          case value
          when 'individual'
            key.failure(text: 'consumer_role_id field should be populated') if values[:consumer_role_id].nil? || !values[:consumer_role_id].is_a?(BSON::ObjectId)
          when 'coverall'
            key.failure(text: 'resident_role_id field should be populated') if values[:resident_role_id].nil? || !values[:resident_role_id].is_a?(BSON::ObjectId)
          when 'employer_sponsored', 'employer_sponsored_cobra'
            key.failure(text: 'employee_role_id field should be populated') if values[:employee_role_id].nil? || !values[:employee_role_id].is_a?(BSON::ObjectId)
            key.failure(text: 'benefit_group_assignment_id field should be populated') if values[:benefit_group_assignment_id].nil? || !values[:benefit_group_assignment_id].is_a?(BSON::ObjectId)
            key.failure(text: 'benefit_sponsorship_id field should be populated') if values[:benefit_sponsorship_id].nil? || !values[:benefit_sponsorship_id].is_a?(BSON::ObjectId)
            key.failure(text: 'sponsored_benefit_package_id field should be populated') if values[:sponsored_benefit_package_id].nil? || !values[:sponsored_benefit_package_id].is_a?(BSON::ObjectId)
            key.failure(text: 'sponsored_benefit_id field should be populated') if values[:sponsored_benefit_id].nil? || !values[:sponsored_benefit_id].is_a?(BSON::ObjectId)
            key.failure(text: 'rating_area_id field should be populated') if values[:rating_area_id].nil? || !values[:rating_area_id].is_a?(BSON::ObjectId)
          end
        end
      end

      # rule(:coverage_kind) do
      #   # Write rules based on coverage_kind
      #   if key? && value
      #     case value
      #     when 'health'
      #     when 'dental'
      #     end
      #   end
      # end

      rule(:enrollment_kind) do
        # Write rules based on enrollment_kind
        if key? && value
          case value
          when 'special_enrollment'
            key.failure(text: 'special_enrollment_period_id field should be populated') if values[:special_enrollment_period_id].nil? || !values[:special_enrollment_period_id].is_a?(BSON::ObjectId)
          # when 'open_enrollment'
          end
        end
      end
    end
  end
end
