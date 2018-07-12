module BenefitMarkets
  module SponsoredBenefits
    # This is an abstract class that represents and documents the interface
    # which must be satisfied by objects returned by any implementation
    # of RosterEntry, via the #group_enrollment method
    class RosterGroupEnrollment
      # Return the date on which the rate schedule is applicable.
      # @return [Date] the rate schedule date
      def rate_schedule_date
        raise NotImplementedError.new("This is a documentation only interface.")
      end

      # The coverage start date.
      # @return [Date] the coverage start date
      def coverage_start_on
        raise NotImplementedError.new("This is a documentation only interface.")
      end

      # Total cost to cover the group.
      # @return [FixNum, BigDecimal] the total cost
      def product_cost_total
        raise NotImplementedError.new("This is a documentation only interface.")
      end

      # Total contribution by the sponsor
      # @return [FixNum, BigDecimal] the total contribution
      def sponsor_contribution_total
        raise NotImplementedError.new("This is a documentation only interface.")
      end

      # The rating area name
      # @return [String] the rating area name
      def rating_area
        raise NotImplementedError.new("This is a documentation only interface.")
      end
      
      # If applicable, the product under which the previous eligibility was
      # determined. This must always be present if there are entries in
      # the #coverage_eligibility_dates hash.
      # @return [::BenefitMarkets::Products::Product] the product
      def previous_product
        raise NotImplementedError.new("This is a documentation only interface.")
      end

      # The selected product.
      # @return [::BenefitMarkets::Products::Product] the product
      def product
        raise NotImplementedError.new("This is a documentation only interface.")
      end

      # A list of member-level enrollment details.
      # @return [Array<RosterEnrollmentMember>] - the list of member enrollment details
      def member_enrollments
        raise NotImplementedError.new("This is a documentation only interface.")
      end
    end
  end
end
