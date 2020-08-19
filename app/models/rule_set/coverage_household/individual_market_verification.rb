module RuleSet
  module CoverageHousehold
    class IndividualMarketVerification
      attr_reader :coverage_household

      def initialize(c_household)
        @coverage_household = c_household
      end

      def applicable?
        coverage_household.active_individual_enrollments.any?
      end

      def roles_for_determination
        coverage_household.active_individual_enrollments.flat_map(&:hbx_enrollment_members).map(&:person).map(&:consumer_role).compact
      end

      def applicants_for_determination
        application = coverage_household.family.latest_applicable_submitted_application
        return [] if !application
        application.applicants
      end

      def determine_next_state
        return(:move_to_pending!) if roles_for_determination.any?(&:ssa_pending?) || roles_for_determination.any?(&:dhs_pending?) || applicants_for_determination.any?(&:verification_pending?)
        return(:move_to_contingent!) if roles_for_determination.any?(&:verification_outstanding?) || roles_for_determination.any?(&:verification_period_ended?) || applicants_for_determination.any?(&:verification_outstanding?)
        :move_to_enrolled!
      end
    end
  end
end
