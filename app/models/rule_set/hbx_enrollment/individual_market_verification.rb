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
        return(:move_to_contingent!) if roles_for_determination.any?(&:verification_outstanding?) || roles_for_determination.any?(&:verification_period_ended?)
        return(:move_to_pending!) if roles_for_determination.any?(&:ssa_pending?) || roles_for_determination.any?(&:dhs_pending?)
        :move_to_enrolled!
      end
    end
  end
end
