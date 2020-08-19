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
        hbx_enrollment.hbx_enrollment_members.map(&:person).map(&:consumer_role).compact
      end

      def applicants_for_determination
        application = hbx_enrollment.family.latest_applicable_submitted_application
        return [] if !application
        application.applicants
      end

      def determine_next_state
        return true, :move_to_enrolled! if (any_outstanding? || verification_ended?) && hbx_enrollment.may_move_to_enrolled?
        member_outstanding = any_outstanding? || verification_ended?
        if any_pending?
          return member_outstanding, :move_to_pending! if hbx_enrollment.may_move_to_pending?
        else
          return member_outstanding, :move_to_enrolled! if hbx_enrollment.may_move_to_enrolled?
        end
        return member_outstanding, :do_nothing
      end

      def any_outstanding?
        roles_for_determination.any?(&:verification_outstanding?) || applicants_for_determination.any?(&:verification_outstanding?)
      end

      def verification_ended?
        roles_for_determination.any?(&:verification_period_ended?)
      end

      def any_pending?
        roles_for_determination.any?(&:ssa_pending?) ||
          roles_for_determination.any?(&:dhs_pending?) ||
          roles_for_determination.any?(&:sci_verified?) ||
          applicants_for_determination.any?(&:verification_pending?)
      end
    end
  end
end
