# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  module Individual
    # Create new enrollment to apply available aggregate enrollment for an existing enrollment.
    class ApplyAggregateToEnrollment
      include Dry::Monads[:result, :do]
      include FloatHelper
      def call(params)
        validated_eligibility   = yield validate(params)
        eligible_enrollments    = yield fetch_enrollments_to_renew(validated_eligibility)
        generate_enrollments    = yield generate_enrollments(eligible_enrollments, params[:eligibility_determination])
        Success(generate_enrollments)
      end

      private

      def validate(params)
        return Failure("Given object is not a valid eligibility determination object") unless params[:eligibility_determination].is_a?(EligibilityDetermination)
        return Failure("No active tax household for given eligibility") unless params[:eligibility_determination].tax_household.present?
        Success(params[:eligibility_determination])
      end

      def fetch_enrollments_to_renew(eligibility_determination)
        enrollments = eligibility_determination.family.active_household.hbx_enrollments.enrolled.individual_market.by_health
        return Failure('Cannot find any IVL health enrollments in any of the active states.') if enrollments.blank?
        enrollment_list = enrollments.reject do |enr|
          next if enr.product.blank?
          enr.product.metal_level_kind == :catastrophic
        end
        enrollment_list.present? ? Success(enrollment_list) : Failure('Cannot find any enrollments with Non-Catastrophic Plan.')
      end

      def generate_enrollments(enrollments, eligibility_determination)
        current_max_aptc = eligibility_determination.max_aptc.to_f
        enrollments.each do |enrollment|
          max_aptc = if EnrollRegistry[:calculate_monthly_aggregate].feature.is_enabled
                       shopping_fm_ids = enrollment.hbx_enrollment_members.pluck(:applicant_id)
                       input_params = { family: enrollment.family,
                                        effective_on: enrollment.effective_on,
                                        shopping_fm_ids: shopping_fm_ids,
                                        subscriber_applicant_id: enrollment&.subscriber&.applicant_id }
                       monthly_aggregate_amount = EnrollRegistry[:calculate_monthly_aggregate] {input_params}
                       monthly_aggregate_amount.success? ? monthly_aggregate_amount.value! : 0
                     else
                       current_max_aptc.to_f
                     end
          default_percentage = EnrollRegistry[:aca_individual_assistance_benefits].setting(:default_applied_aptc_percentage).item
          applied_percentage = enrollment.elected_aptc_pct > 0 ? enrollment.elected_aptc_pct : default_percentage
          applied_aptc = float_fix(max_aptc * applied_percentage)
          attrs = {enrollment_id: enrollment.id, elected_aptc_pct: applied_percentage, aptc_applied_total: applied_aptc}
          ::Insured::Forms::SelfTermOrCancelForm.for_aptc_update_post(attrs)
        end
        Success("Aggregate amount applied on to enrollments")
      end
    end
  end
end
