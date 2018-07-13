module BenefitMarkets
  module SponsoredBenefits
    # This is an abstract class that represents and documents the interface
    # which must be satisfied by objects returned by any implementation
    # of RosterEntry, via the #members method.
    class RosterMember
      # Return the dependent's id.
      def member_id
        raise NotImplementedError.new("This is a documentation only interface.")
      end

      # Return the date of birth.
      def dob
        raise NotImplementedError.new("This is a documentation only interface.")
      end

      # Relationship to the primary.
      # @return [Symbol] the relationship
      def relationship
        raise NotImplementedError.new("This is a documentation only interface.")
      end

      # Return if the member is disabled.
      # @return [Boolean] is the member is disabled
      def is_disabled?
        raise NotImplementedError.new("This is a documentation only interface.")
      end

      # Return if the member is the primary.
      # @return [Boolean] is this a primary member?
      def is_primary_member?
        raise NotImplementedError.new("This is a documentation only interface.")
      end
    end
  end
end
