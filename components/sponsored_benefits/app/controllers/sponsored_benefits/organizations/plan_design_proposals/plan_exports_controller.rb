# frozen_string_literal: true

module SponsoredBenefits
  module Organizations
    class PlanDesignProposals::PlanExportsController < ApplicationController

      # skip_before_action :verify_authenticity_token

      def create
        @plan_design_organization = plan_design_organization
        find_or_build_benefit_group
        @census_employees = sponsorship.census_employees
        if @benefit_group
          @service = SponsoredBenefits::Services::PlanCostService.new({benefit_group: @benefit_group})
          @benefit_group.build_estimated_composite_rates if @benefit_group.sole_source?
          @plan = @benefit_group.reference_plan
          dental_plan = @benefit_group.dental_reference_plan
          @employer_contribution_amount = @service.monthly_employer_contribution_amount(@plan)
          @employer_dental_contribution_amount = @service.monthly_employer_contribution_amount(dental_plan) if dental_plan.present?
          @benefit_group_costs = @benefit_group.employee_costs_for_reference_plan(@service)
          @benefit_group_dental_costs = @benefit_group.employee_costs_for_reference_plan(@service, dental_plan) if dental_plan.present?
          @qhps = ::Products::QhpCostShareVariance.find_qhp_cost_share_variances(plan_array(@plan), plan_design_proposal.effective_date.year, "Health")
        end

        render pdf: 'plan_details_export', dpi: 72,
               template: 'sponsored_benefits/organizations/plan_design_proposals/plan_exports/_plan_details.html.erb',
               disposition: 'attachment',
               locals: { benefit_group: @benefit_group, plan_design_proposal: plan_design_proposal, qhps: @qhps, plan: @plan, visit_types: visit_types, sbc_included: sbc_included }
      end

      private

      helper_method :plan_design_form, :plan_design_organization, :plan_design_proposal, :sponsorship, :visit_types

      def plan_design_proposal
        @plan_design_proposal ||= SponsoredBenefits::Organizations::PlanDesignProposal.find(params[:plan_design_proposal_id])
      end

      def plan_design_organization
        @plan_design_organization ||= plan_design_proposal.plan_design_organization
      end

      def sponsorship
        @sponsorship ||= plan_design_proposal.profile.benefit_sponsorships.first
      end

      def find_or_build_benefit_group
        persisted_benefit_group = sponsorship.benefit_applications.first.benefit_groups.first

        if persisted_benefit_group.present? && kind == 'dental'
          if dental_benefit_params[:dental_relationship_benefits].blank?
            benefit_params = {
              dental_reference_plan_id: persisted_benefit_group.dental_reference_plan_id,
              dental_relationship_benefits: persisted_benefit_group.dental_relationship_benefits,
              dental_plan_option_kind: persisted_benefit_group.dental_plan_option_kind
            }
          end
          @benefit_group = sponsorship.benefit_applications.first.benefit_groups.build((benefit_params || dental_benefit_params).as_json)
          @benefit_group.assign_attributes({
                                             relationship_benefits: persisted_benefit_group.relationship_benefits,
                                             reference_plan_id: persisted_benefit_group.reference_plan_id,
                                             elected_dental_plans: @benefit_group.elected_dental_plans_by_option_kind,
                                             elected_plans: persisted_benefit_group.elected_plans_by_option_kind.to_a,
                                             plan_option_kind: persisted_benefit_group.plan_option_kind
                                           })
        elsif benefit_group_params.present?
          @benefit_group = sponsorship.benefit_applications.first.benefit_groups.build(benefit_group_params.as_json)
          @benefit_group.elected_plans = @benefit_group.elected_plans_by_option_kind.to_a
        else
          @benefit_group = sponsorship.benefit_applications.first.benefit_groups.build(persisted_benefit_group.as_json)
          @benefit_group.elected_plans = @benefit_group.elected_plans_by_option_kind.to_a
        end
      end

      def plan_array(plan)
        ::Plan.where(:_id => { '$in': [plan.id] }).map(&:hios_id)
      end

      def plan_design_form
        SponsoredBenefits::Forms::PlanDesignProposal.new(organization: plan_design_organization, proposal_id: params[:plan_design_proposal_id])
      end

      def visit_types
        @visit_types ||= ::Products::Qhp::VISIT_TYPES
      end

      def sbc_included
        params[:sbc_included] == 'true'
      end

      def kind
        params.require(:benefit_group).require(:kind)
      end

      def benefit_group_params
        params.require(:benefit_group).permit(
          :reference_plan_id,
          :plan_option_kind,
          relationship_benefits_attributes: [:relationship, :premium_pct, :offered],
          composite_tier_contributions_attributes: [:composite_rating_tier, :employer_contribution_percent, :offered]
        )
      end

      def dental_benefit_params
        {
          dental_reference_plan_id: benefit_group_params[:reference_plan_id],
          dental_relationship_benefits: benefit_group_params[:relationship_benefits_attributes],
          dental_plan_option_kind: benefit_group_params[:plan_option_kind]
        }
      end
    end
  end
end
