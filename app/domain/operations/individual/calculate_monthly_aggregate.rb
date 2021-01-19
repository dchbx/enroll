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
        values               = yield validate(params)
        amount_consumed      = yield consumed_aptc_amount(values)
        calculated_aggregate = yield calculate_monthly_aggregate(amount_consumed)

        Success(calculated_aggregate)
      end

      private

      def validate(params)
        return Failure('Given object is not a valid family object.') unless params[:family].is_a?(Family)
        return Failure('Given effective_on not a valid Date object.') unless params[:effective_on].is_a?(Date)
        return Failure('Shopping Enrollment Family Member Ids are not present.') if params[:shopping_fm_ids].blank?
        return Failure('Subscriber Applicant Id is missing.') if params[:subscriber_applicant_id].blank?

        Success(params)
      end

      def consumed_aptc_amount(values)
        @effective_on = values[:effective_on]
        @family = values[:family]
        @shopping_fm_ids = values[:shopping_fm_ids]
        @subscriber_applicant_id = values[:subscriber_applicant_id]

        aptc_enrollments = HbxEnrollment.yearly_aggregate(@family.id, @effective_on.year)
        consumed_aptc = 0
        aptc_enrollments.each do |enrollment|
          consumed_aptc += aptc_amount_consumed_by_enrollment(enrollment)
        end
        Success(consumed_aptc)
      end

      def aptc_amount_consumed_by_enrollment(enrollment)
        termination_date = calculate_termination_date(enrollment)
        @old_enr_effective_on = enrollment.effective_on
        @applied_aptc = enrollment.applied_aptc_amount.to_f
        first_month_aptc = aptc_consumed_in_effective_month(termination_date)
        full_months_aptc = aptc_consumed_in_full_months(termination_date)
        last_month_aptc  = aptc_consumed_in_terminated_month(termination_date)
        first_month_aptc + full_months_aptc + last_month_aptc
      end

      def aptc_consumed_in_effective_month(termination_date)
        total_days = @old_enr_effective_on.end_of_month.day
        no_of_days_aptc_consumed =
          if @old_enr_effective_on == @old_enr_effective_on.beginning_of_month
            if termination_date <= @old_enr_effective_on
              0
            elsif termination_date.month != @old_enr_effective_on.month
              total_days
            elsif termination_date.month == @old_enr_effective_on.month
              termination_date.day - (@old_enr_effective_on.day - 1)
            end
          else
            total_days - (@old_enr_effective_on.day - 1)
          end
        no_of_days_aptc_consumed.fdiv(total_days) * @applied_aptc
      end

      def aptc_consumed_in_full_months(termination_date)
        if (termination_date.month - 1) <= @old_enr_effective_on.month
          0
        else
          (termination_date.month - 1) - @old_enr_effective_on.month
        end * @applied_aptc
      end

      def aptc_consumed_in_terminated_month(termination_date)
        total_days = termination_date.end_of_month.day
        if @old_enr_effective_on.month == termination_date.month
          0
        elsif termination_date < @old_enr_effective_on
          0
        else
          termination_date.day.fdiv(total_days) * @applied_aptc
        end
      end

      def calculate_termination_date(enrollment)
        enrollment.terminated_on || new_temination_date(enrollment)
      end

      def new_temination_date(enrollment)
        if enrollment.subscriber.applicant_id.to_s == @subscriber_applicant_id.to_s
          end_date = EnrollRegistry[:calculate_monthly_aggregate].settings(:termination_date).item
          end_date == :end_of_month ? @effective_on - 1.day : enrollment.effective_on.end_of_year
        else
          enrollment.effective_on.end_of_year
        end
      end

      #logic to calculate the monthly Aggregate
      def calculate_monthly_aggregate(consumed_aptc)
        latest_max_aptc = @family.active_household.latest_active_tax_household_with_year(@effective_on.year).latest_eligibility_determination.max_aptc.to_f
        available_annual_aggregate = (latest_max_aptc * 12) - consumed_aptc.to_f
        monthly_max = calculated_new_monthly_aggregate(available_annual_aggregate)
        # base_enrollment.update_attributes(aggregate_aptc_amount: monthly_max)
        Success(monthly_max)
      end

      def calculated_new_monthly_aggregate(available_annual_aggregate)
        total_no_of_months = pct_of_effective_month + number_of_remaining_full_months
        round_down_float_two_decimals(available_annual_aggregate / total_no_of_months)
      end

      def pct_of_effective_month
        total_days = @effective_on.end_of_month.day
        (total_days - (@effective_on.day - 1)) / total_days.to_f
      end

      def number_of_remaining_full_months
        12 - @effective_on.month
      end
    end
  end
end
