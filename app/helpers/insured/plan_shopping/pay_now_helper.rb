#frozen_string_literal: true

module Insured
  module PlanShopping
    #helper related to paynow feature
    module PayNowHelper
      def show_pay_now?(source, hbx_enrollment)
        return false unless EnrollRegistry[:pay_now_functionality].feature.is_enabled
        if source == "Plan Shopping"
          can_pay_now?(hbx_enrollment) && !pay_now_button_timed_out?(hbx_enrollment) ? true : false
        else
          can_pay_now?(hbx_enrollment) && past_effective_on?(hbx_enrollment) ? true : false
        end
      end

      def can_pay_now?(hbx_enrollment)
        return true if carrier_with_payment_option?(hbx_enrollment) && individual?(hbx_enrollment) && (has_break_in_coverage_enrollments?(hbx_enrollment) || !has_any_previous_enrollments?(hbx_enrollment))
      end

      def carrier_with_payment_option?(hbx_enrollment)
        hbx_enrollment.product.issuer_profile.legal_name == EnrollRegistry[:pay_now_functionality].setting(:carriers).item
      end

      def individual?(hbx_enrollment)
        hbx_enrollment.kind.in?(['individual', 'coverall'])
      end

      def has_any_previous_enrollments?(hbx_enrollment)
        carrier = EnrollRegistry[:pay_now_functionality].setting(:carriers).item
        all_kaiser_enrollments = hbx_enrollment.family.hbx_enrollments.where(:aasm_state.nin => ["inactive", "shopping", "coverage_canceled"]).select do |enr|
          next if enr.product.blank? || enr.subscriber.blank? || enr.is_shop?
          enr.product.issuer_profile.legal_name == carrier && enr.effective_on.year == hbx_enrollment.effective_on.year && enr.subscriber.id == hbx_enrollment.subscriber.id
        end
        enrollments = all_kaiser_enrollments - hbx_enrollment.to_a
        enrollments.present? ? true : false
      end

      def pay_now_button_timed_out?(hbx_enrollment)
        covered_time = hbx_enrollment.workflow_state_transitions.where(to_state: 'coverage_selected').first
        return true if covered_time.blank?
        covered_time.transition_at + 15.minutes <= Time.now
      end

      def past_effective_on?(hbx_enrollment)
        return true if hbx_enrollment.effective_on > TimeKeeper.date_of_record
      end

      def has_break_in_coverage_enrollments?(hbx_enrollment)
        enrollments = hbx_enrollment.family.enrollments.current_year.where(aasm_state: "coverage_terminated")
        enrollments.any? { |enr| enr.terminated_on.year == hbx_enrollment.effective_on.year && (hbx_enrollment.effective_on - enr.terminated_on) > 1 }
      end
    end
  end
end