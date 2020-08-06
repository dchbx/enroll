# frozen_string_literal: true

module Insured
  module PlanShopping
    module ReceiptHelper
      def show_pay_now?
        return false
        (carrier_with_payment_option? && individual? && (!has_any_previous_kaiser_enrollments? || has_break_in_coverage_enrollments?)) && pay_now_button_timed_out?
      end

      def carrier_with_payment_option?
        @enrollment.product.issuer_profile.legal_name == 'Kaiser'
      end

      def individual?
        @enrollment.kind.in?(['individual', 'coverall'])
      end

      def has_any_previous_kaiser_enrollments?
        all_kaiser_enrollments = @enrollment.family.hbx_enrollments.select { |enr| enr.product.issuer_profile.legal_name == 'Kaiser' && enr.effective_on.year == @enrollment.effective_on.year }
        enrollments = all_kaiser_enrollments - @enrollment.to_a
        enrollments.present? ? true : false
      end

      def pay_now_button_timed_out?
        @enrollment.submitted_at + 15.minutes > TimeKeeper.datetime_of_record
      end

      def has_break_in_coverage_enrollments?
        enrollments = @enrollment.family.enrollments.current_year.where(aasm_state: "coverage_terminated")
        enrollments.any? { |enr| enr.product.issuer_profile.legal_name == 'Kaiser' && enr.terminated_on.year == @enrollment.effective_on.year && (@enrollment.effective_on - enr.terminated_on) > 1 }
      end
    end
  end
end