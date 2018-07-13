module BenefitSponsors
  module PlanDesigns
    class BuildBenefitPackage < CompositeTask

      def initialize

        super("Define benefit products that a sponsor will offer to a set of members")

# NOTE: subtasks are listed here, but need to be moved into subclasses, per indentation
# BenefitPackage as interface
        # add_subtask(BenefitSponsors::PlanDesigns::SetProbationPeriod.new)
        # add_subtask(BenefitSponsors::PlanDesigns::GetEligiblePackageList.new)

# SponsoredBenefit as interface
        # add_subtask(BenefitSponsors::PlanDesigns::TransformPackageToSponsoredBenefit.new)

        #   add_subtask(BenefitSponsors::PlanDesigns::BuildHealthSponsoredBenefit.new)

        #     add_subtask(BenefitSponsors::PlanDesigns::SetHealthOneIssuerOptions.new)
        #       add_subtask(BenefitSponsors::PlanDesigns::SetSponsorContribution.new)

        #     add_subtask(BenefitSponsors::PlanDesigns::SetHealthOnePlanOptions.new)
        #       add_subtask(BenefitSponsors::PlanDesigns::SetSponsorContribution.new)

        #     add_subtask(BenefitSponsors::PlanDesigns::SetHealthCompositePlanOptions.new)
        #       add_subtask(BenefitSponsors::PlanDesigns::SetSponsorContribution.new)
        #       add_subtask(BenefitSponsors::PlanDesigns::CalculateCompositeRate.new)

        #     add_subtask(BenefitSponsors::PlanDesigns::SetHealthMetalLevelOptions.new)
        #       add_subtask(BenefitSponsors::PlanDesigns::SetSponsorContribution.new)

        #   add_subtask(BenefitSponsors::PlanDesigns::BuildDentalSponsoredBenefit.new)

        #     add_subtask(BenefitSponsors::PlanDesigns::SetDentalOnePlanOptions.new)
        #       add_subtask(BenefitSponsors::PlanDesigns::SetSponsorContribution.new)

        #     add_subtask(BenefitSponsors::PlanDesigns::SetDentalManyPlanOptions.new)
        #       add_subtask(BenefitSponsors::PlanDesigns::SetSponsorContribution.new)

        # add_subtask(BenefitSponsors::PlanDesigns::AssociateMembers.new) # If default BenefitPackage

      end
    end
  end
end





