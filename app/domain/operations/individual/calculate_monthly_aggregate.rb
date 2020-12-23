# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  module Individual
    # Calculate Yearly Aggregate amount based on current enrollment
    class CalculateMonthlyAggregate
      include Dry::Monads[:result, :do]
      include FloatHelper

      def call(params)
        validated_enrollment = yield validate(params)
        amount_consumed      = yield consumed_aptc_amount(validated_enrollment)
        calculated_aggregate = yield calculate_monthly_aggregate(validated_enrollment, amount_consumed)

        Success(calculated_aggregate)
      end

      private

      def validate(params)
        return Failure("Given object is not a valid hbx enrollment object") unless params[:hbx_enrollment].is_a?(HbxEnrollment)
        return Failure("Enrollment has no family") unless params[:hbx_enrollment].family.present?
        return Failure("No household found for enrollment") unless params[:hbx_enrollment].household.present?
        Success(params[:hbx_enrollment])
      end

      def consumed_aptc_amount(base_enrollment)
        family = base_enrollment.family
        aptc_enrollments = HbxEnrollment.yearly_aggregate(family.id, base_enrollment.effective_on.year)
        consumed_aptc = 0
        aptc_enrollments.each do |enrollment|
          consumed_aptc += aptc_amount_consumed_by_enrollment(enrollment, base_enrollment)
        end
        Success(consumed_aptc)
      end

      def aptc_amount_consumed_by_enrollment(enrollment, base_enrollment)
        termination_date = calculate_termination_date(enrollment, base_enrollment)
        first_month_aptc = aptc_consumed_in_effective_month(enrollment, termination_date)
        full_months_aptc = aptc_consumed_in_full_months(enrollment, termination_date)
        last_month_aptc = aptc_consumed_in_terminated_month(enrollment, termination_date)
        first_month_aptc + full_months_aptc + last_month_aptc
      end

      def aptc_consumed_in_effective_month(enrollment, termination_date)
        effective_on = enrollment.effective_on
        applied_aptc = enrollment.applied_aptc_amount.to_f
        total_days = effective_on.end_of_month.day
        no_of_days_aptc_consumed =
          if effective_on == effective_on.beginning_of_month
            if termination_date.month != enrollment.effective_on.month
              total_days
            elsif termination_date.month == enrollment.effective_on.month
              termination_date.day - (effective_on.day - 1)
            end
          else
            total_days - (effective_on.day - 1)
          end
        no_of_days_aptc_consumed.fdiv(total_days) * applied_aptc
      end

      def aptc_consumed_in_full_months(enrollment, termination_date)
        effective_on = enrollment.effective_on
        applied_aptc = enrollment.applied_aptc_amount.to_f
        if (termination_date.month - 1) <= effective_on.month
          0
        else
          (termination_date.month - 1) - effective_on.month
        end * applied_aptc
      end

      def aptc_consumed_in_terminated_month(enrollment, termination_date)
        effective_on   = enrollment.effective_on
        applied_aptc   = enrollment.applied_aptc_amount.to_f
        total_days     = termination_date.end_of_month.day
        if effective_on.month == termination_date.month
          0
        else
          termination_date.day.fdiv(total_days) * applied_aptc
        end
      end

      def calculate_termination_date(enrollment, base_enrollment)
        enrollment.terminated_on || (base_enrollment.effective_on - 1.day)
      end

      #logic to calculate the monthly Aggregate
      def calculate_monthly_aggregate(base_enrollment, consumed_aptc)
        latest_max_aptc = base_enrollment.family.active_household.latest_active_tax_household_with_year(base_enrollment.effective_on.year).latest_eligibility_determination.max_aptc.to_f
        available_annual_aggregate = (latest_max_aptc * 12) - consumed_aptc.to_f
        monthly_max = calculated_new_monthly_aggregate(base_enrollment, available_annual_aggregate)
        Success(monthly_max)
      end

      def calculated_new_monthly_aggregate(base_enrollment, available_annual_aggregate)
        total_no_of_months = pct_of_effective_month(base_enrollment) + number_of_remaining_full_months(base_enrollment)
        round_down_float_two_decimals(available_annual_aggregate / total_no_of_months)
      end

      def pct_of_effective_month(base_enrollment)
        total_days = base_enrollment.effective_on.end_of_month.day
        (total_days - (base_enrollment.effective_on.day - 1)) / total_days.to_f
      end

      def number_of_remaining_full_months(base_enrollment)
        12 - base_enrollment.effective_on.month
      end
    end
  end
end
