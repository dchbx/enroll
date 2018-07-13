module BenefitSponsors
  module SponsoredBenefits
    # Chose the correct strategy for roster optimization and execute it.
    class RosterEligibilityOptimizer

      def initialize(contribution_model)
        @optimizer = if contribution_model.many_simultaneous_contribution_units?
          RelationshipRosterEligibilityOptimizer.new
        else
          TieredRosterEligibilityOptimizer.new
        end
      end
      
      # Deprecated 
      def calculate_optimal_group_for(contribution_model, covered_roster_entry, sponsor_contribution)
        @optimizer.calculate_optimal_group_for(contribution_model, covered_roster_entry, sponsor_contribution)
      end

      def optimal_group_for(covered_roster_entry, sponsored_benefit)
        calculate_optimal_group_for(sponsored_benefit.contribution_model, covered_roster_entry, sponsored_benefit.sponsor_contribution)
      end
    end
  end
end
