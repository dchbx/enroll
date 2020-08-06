# frozen_string_literal: true

module SponsoredBenefits
  module Organizations
    class PlanDesignProposals::ContributionsController < ApplicationController

      def index
        benefit_group.build_estimated_composite_rates if benefit_group.sole_source?
        benefit_group.set_bounding_cost_plans
        @service = SponsoredBenefits::Services::PlanCostService.new({benefit_group: benefit_group})
        @employer_contribution_amount = @service.monthly_employer_contribution_amount

        @benefit_group_costs = benefit_group.employee_costs_for_reference_plan(@service)
      end

      private

      helper_method :plan_design_proposal, :benefit_group, :kind

      def plan_design_proposal
        @plan_design_proposal ||= PlanDesignProposal.find(params[:plan_design_proposal_id])
      end

      def sponsorship
        @sponsorship ||= plan_design_proposal.profile.benefit_sponsorships.first
      end

      def kind
        @kind ||= params[:benefit_group][:kind]
      end

      def benefit_group
        return @benefit_group if defined? @benefit_group
        @benefit_group ||= sponsorship.benefit_applications.first.benefit_groups.build(benefit_group_params)

        # This always take one benefit group at a time to calculate costs. we never save this to database.
        @benefit_group.dental_relationship_benefits = @benefit_group.relationship_benefits if @benefit_group.reference_plan.dental?
        @benefit_group
      end

      def benefit_group_params
        params.require(:benefit_group).permit(
          :reference_plan_id,
          :plan_option_kind,
          :elected_dental_plans,
          relationship_benefits_attributes: [:relationship, :premium_pct, :offered],
          composite_tier_contributions_attributes: [:composite_rating_tier, :employer_contribution_percent, :offered]
        )
      end
    end
  end
end
