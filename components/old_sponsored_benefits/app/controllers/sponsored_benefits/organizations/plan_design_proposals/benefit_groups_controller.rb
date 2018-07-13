module SponsoredBenefits
  module Organizations
    class PlanDesignProposals::BenefitGroupsController < ApplicationController

      def create
        update_benefit_group_attributes if benefit_group.persisted?

        benefit_group.title = "Benefit Group Created for: #{plan_design_organization.legal_name} by #{plan_design_organization.broker_agency_profile.legal_name}"
        benefit_group.elected_plans = benefit_group.elected_plans_by_option_kind

        if benefit_group.sole_source?
          benefit_group.build_relationship_benefits
          benefit_group.estimate_composite_rates
        else
          benefit_group.build_composite_tier_contributions
        end
        benefit_group.set_bounding_cost_plans

        if plan_design_proposal.save
          render json: { url: new_organizations_plan_design_proposal_plan_review_path(plan_design_proposal) }
        else
          flash[:error] = "Something went wrong"
        end
      end

      private
        helper_method :plan_design_form, :plan_design_organization, :plan_design_proposal

        def plan_design_proposal
          @plan_design_proposal ||= SponsoredBenefits::Organizations::PlanDesignProposal.find(params[:plan_design_proposal_id])
        end

        def plan_design_organization
          @plan_design_organization ||= plan_design_proposal.plan_design_organization
        end

        def sponsorship
          @sponsorship ||= plan_design_proposal.profile.benefit_sponsorships.first
        end

        def benefit_group
          @benefit_group ||= sponsorship.benefit_applications.first.benefit_groups.first || sponsorship.benefit_applications.first.benefit_groups.build(benefit_group_params)
        end

        def plan_design_form
          SponsoredBenefits::Forms::PlanDesignProposal.new(organization: plan_design_organization, proposal_id: params[:plan_design_proposal_id])
        end

        def update_benefit_group_attributes
          benefit_group.composite_tier_contributions.destroy_all
          benefit_group.relationship_benefits.destroy_all
          benefit_group.update_attributes(benefit_group_params)
        end

        def benefit_group_params
          params.require(:benefit_group).permit(
                      :reference_plan_id,
                      :plan_option_kind,
                      relationship_benefits_attributes: [:relationship, :premium_pct, :offered],
                      composite_tier_contributions_attributes: [:composite_rating_tier, :employer_contribution_percent, :offered]
          )
        end
    end
  end
end
