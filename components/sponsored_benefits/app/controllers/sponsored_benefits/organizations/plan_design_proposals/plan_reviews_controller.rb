module SponsoredBenefits
  module Organizations
    class PlanDesignProposals::PlanReviewsController < ApplicationController

      def new
        @plan_design_organization = plan_design_organization
        @benefit_group = benefit_group
        @census_employees = sponsorship.census_employees

        if @benefit_group
          @plan = @benefit_group.reference_plan
          @employer_contribution_amount = @benefit_group.monthly_employer_contribution_amount
          @benefit_group_costs = @benefit_group.employee_costs_for_reference_plan
          @min_employee_cost = benefit_group.monthly_min_employee_cost
          @max_employee_cost = benefit_group.monthly_max_employee_cost
          @qhps = ::Products::QhpCostShareVariance.find_qhp_cost_share_variances(plan_array(@plan), plan_design_proposal.effective_date.year, "Health")
        end
      end

      def show
        @plan_design_organization = plan_design_organization
        @benefit_group = benefit_group
        @census_employees = sponsorship.census_employees

        if @benefit_group
          @plan = @benefit_group.reference_plan
          @employer_contribution_amount = @benefit_group.monthly_employer_contribution_amount
          @benefit_group_costs = @benefit_group.employee_costs_for_reference_plan
          @min_employee_cost = benefit_group.monthly_min_employee_cost
          @max_employee_cost = benefit_group.monthly_max_employee_cost
          @qhps = ::Products::QhpCostShareVariance.find_qhp_cost_share_variances(plan_array(@plan), plan_design_proposal.effective_date.year, "Health")
        end
        render pdf: 'plan_review_export',
               template: 'sponsored_benefits/organizations/plan_design_proposals/plan_reviews/show.html.erb',
               disposition: 'attachment'
      end

      private
        helper_method :plan_design_form, :plan_design_organization, :plan_design_proposal, :visit_types

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

        def benefit_group_params
          params.require(:benefit_group).permit(
                      :reference_plan_id,
                      :plan_option_kind,
                      relationship_benefits_attributes: [:relationship, :premium_pct, :offered],
                      composite_tier_contributions_attributes: [:composite_rating_tier, :employer_contribution_percent, :offered]
          )
        end

        def plan_array(plan)
           ::Plan.where(:_id => { '$in': [plan.id] } ).map(&:hios_id)
        end

        def visit_types
          @visit_types ||= ::Products::Qhp::VISIT_TYPES
        end
    end
  end
end
