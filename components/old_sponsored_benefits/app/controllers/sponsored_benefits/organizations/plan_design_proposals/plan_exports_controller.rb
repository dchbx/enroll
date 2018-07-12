module SponsoredBenefits
  module Organizations
    class PlanDesignProposals::PlanExportsController < ApplicationController

      def new
        @plan_design_organization = plan_design_organization
        @benefit_group = benefit_group
        @census_employees = sponsorship.census_employees

        if @benefit_group
          @plan = @benefit_group.reference_plan
          @employer_contribution_amount = @benefit_group.monthly_employer_contribution_amount
          @benefit_group_costs = @benefit_group.employee_costs_for_reference_plan
          @qhps = ::Products::QhpCostShareVariance.find_qhp_cost_share_variances(plan_array(@plan), plan_design_proposal.effective_date.year, "Health")
        end

        render pdf: 'plan_details_export',
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

        def benefit_group
          @benefit_group ||= sponsorship.benefit_applications.first.benefit_groups.first || sponsorship.benefit_applications.first.benefit_groups.build(benefit_group_params)
        end

        def plan_array(plan)
           ::Plan.where(:_id => { '$in': [plan.id] } ).map(&:hios_id)
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
    end
  end
end
