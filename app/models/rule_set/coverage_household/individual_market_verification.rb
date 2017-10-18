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
        coverage_household.active_individual_enrollments.flat_map(&:hbx_enrollment_members).map(&:person).map(&:consumer_role)
      end

      def determine_next_state
        return(:move_to_pending!) if (roles_for_determination.any?(&:ssa_pending?) || roles_for_determination.any?(&:dhs_pending?) || roles_for_determination.any?(&:income_pending?) || roles_for_determination.any?(&:mec_pending?))
        return(:move_to_contingent!) if roles_for_determination.any?(&:verification_outstanding?) || roles_for_determination.any?(&:verification_period_ended?)
        :move_to_enrolled!
      end
    end
  end
end
