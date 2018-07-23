module BenefitMarkets
  module SponsoredBenefits
    # This is an abstract class that represents and documents the interface
    # which must be satisfied by objects returned by any implementation
    # of RosterGroupEnrollment, via the #member_enrollments method
    class RosterEnrollmentMember
      # Return the member's id.
      # @return [Object] the member id
      def member_id
        raise NotImplementedError.new("This is a documentation only interface.")
      end

      # Return the date from which the premium is eligible to be calculated
      # for each member.
      # Can differ from the coverage_start_date for the group.
      # It is this rate date that should be used for the 'age on coverage'
      # calculation.
      # @return [Date] coverage eligibility date.
      def coverage_eligibility_on
        raise NotImplementedError.new("This is a documentation only interface.")
      end

      # Cost to cover this member.
      # @return [FixNum, BigDecimal] the cost
      def product_price
        raise NotImplementedError.new("This is a documentation only interface.")
      end

      # Contribution by the sponsor for this member
      # @return [FixNum, BigDecimal] the contribution
      def sponsor_contribution
        raise NotImplementedError.new("This is a documentation only interface.")
      end
    end
  end
end
