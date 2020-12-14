# frozen_string_literal: true

module Operations
  module Individual
    class CalculateYearlyAggregate
      include Dry::Monads[:result, :do]
      include FloatHelper
      def call(hbx_enrollment:)
        validated_enrollment = yield validate(hbx_enrollment)
        amount_consumed = yield amount_consumed(validated_enrollment)
        calculated_aggregate = yield calculate_yearly_aggregate(validated_enrollment, amount_consumed)
        Success(calculated_aggregate)
      end

      private

      def validate(hbx_enrollment)
        return Failure("Given object is not a valid hbx enrollment object") unless hbx_enrollment.is_a?(HbxEnrollment)
        return Failure("Enrollment has no family") unless hbx_enrollment.family.present?
        return Failure("No household found for enrollment") unless hbx_enrollment.household.present?
        Success(hbx_enrollment)
      end

      def amount_consumed(base_enrollment)
        family = base_enrollment.family
        aptc_enrollments = family.active_household.hbx_enrollments_with_consumed_aptc_by_year(base_enrollment.effective_on.year)
        consumed_aptc = 0
        aptc_enrollments.each do |enrollment|
          termination_date = enrollment.terminated_on || (base_enrollment.effective_on - 1.day)
          months_consumed = termination_date.next_month.month - enrollment.effective_on.month
          amount_consumed = enrollment.applied_aptc_amount.to_f * months_consumed
          consumed_aptc += amount_consumed
        end
        Success(consumed_aptc)
      end

      #logic to calculate the yearly Aggregate
      def calculate_yearly_aggregate(base_enrollment, consumed_aptc)
        latest_max_aptc = base_enrollment.family.active_household.latest_active_tax_household_with_year(base_enrollment.effective_on.year).latest_eligibility_determination.max_aptc.to_f
        available_annual_aggregate = (latest_max_aptc * 12) - consumed_aptc
        available_monthly_aggregate = available_annual_aggregate / (12 - (base_enrollment.effective_on - 1.day).month)
        available_monthly_aggregate = (available_monthly_aggregate < 0) ? 0 : available_monthly_aggregate
        Success(available_monthly_aggregate)
      end
    end
  end
end