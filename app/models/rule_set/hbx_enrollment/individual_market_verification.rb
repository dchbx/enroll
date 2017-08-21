module RuleSet
  module HbxEnrollment
    class IndividualMarketVerification
      attr_reader :hbx_enrollment

      def initialize(h_enrollment)
        @hbx_enrollment = h_enrollment
      end

      def applicable?
        (!hbx_enrollment.plan_id.nil?) &&
          hbx_enrollment.affected_by_verifications_made_today? && (!hbx_enrollment.benefit_sponsored?)
      end

      def roles_for_determination
        hbx_enrollment.hbx_enrollment_members.map(&:person).map(&:consumer_role)
      end

      def determine_next_state
        return :do_nothing if (any_outstanding? || verification_ended?) && hbx_enrollment.enrolled_contingent?
        return(:move_to_contingent!) if (any_outstanding? || verification_ended?) && hbx_enrollment.may_move_to_contingent?
        return(:move_to_pending!) if (any_pending? && hbx_enrollment.may_move_to_pending?)
        return(:move_to_enrolled!) if hbx_enrollment.may_move_to_enrolled?
        :do_nothing
      end

      def any_outstanding?
        roles_for_determination.any?(&:verification_outstanding?)
      end

      def verification_ended?
        roles_for_determination.any?(&:verification_period_ended?)
      end

      def any_pending?
        roles_for_determination.any?(&:ssa_pending?) || roles_for_determination.any?(&:dhs_pending?)
      end
    end
  end
end
