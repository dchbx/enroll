# frozen_string_literal: true

module Insured
  module PlanShopping
    module ReceiptHelper
      def show_pay_now?
        return false unless EnrollRegistry[:pay_now_functionality].feature.is_enabled
        (carrier_with_payment_option? && individual? && (has_break_in_coverage_enrollments? || !has_any_previous_kaiser_enrollments?)) && !pay_now_button_timed_out?
      end

      def carrier_with_payment_option?
        @enrollment.product.issuer_profile.legal_name == EnrollRegistry[:pay_now_functionality].setting(:carriers).item
      end

      def individual?
        @enrollment.kind.in?(['individual', 'coverall'])
      end

      def has_any_previous_kaiser_enrollments?
        carrier = EnrollRegistry[:pay_now_functionality].setting(:carriers).item
        all_kaiser_enrollments = @enrollment.family.hbx_enrollments.where(:aasm_state.nin => ["inactive", "shopping", "coverage_canceled"]).select do |enr|
          next if enr.product.blank? || enr.subscriber.blank? || enr.is_shop?
          enr.product.issuer_profile.legal_name == carrier && enr.effective_on.year == @enrollment.effective_on.year && enr.subscriber.id == @enrollment.subscriber.id
        end
        enrollments = all_kaiser_enrollments - @enrollment.to_a
        enrollments.present? ? true : false
      end

      def pay_now_button_timed_out?
        covered_time = @enrollment.workflow_state_transitions.where(to_state: 'coverage_selected').first
        return true if covered_time.blank?
        covered_time.transition_at + 15.minutes <= Time.now
      end

      def has_break_in_coverage_enrollments?
        enrollments = @enrollment.family.enrollments.current_year.where(aasm_state: "coverage_terminated")
        enrollments.any? { |enr| enr.terminated_on.year == @enrollment.effective_on.year && (@enrollment.effective_on - enr.terminated_on) > 1 }
      end
    end
  end
end