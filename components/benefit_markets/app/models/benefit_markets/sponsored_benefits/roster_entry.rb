# frozen_string_literal: true

module BenefitMarkets
  module SponsoredBenefits
    # This is an abstract class that represents and documents the interface
    # which must be satisfied by objects returned by any implementation of
    # Roster's #each method.
    class RosterEntry
      # The members.
      # @return [Array<RosterMember>]
      def members
        raise NotImplementedError, "This is a documentation only interface."
      end

      # If applicable, the enrollment/coverage data for this group.
      # @return [RosterGroupEnrollment]
      def group_enrollment
        raise NotImplementedError, "This is a documentation only interface."
      end
    end
  end
end
