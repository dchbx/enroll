module SponsoredBenefits
  module Organizations
    class PlanDesignProposals::PlanComparisonsController < ApplicationController
      include ApplicationHelper

        def new
          @sort_by = params[:sort_by].rstrip
          # Sorting by the same parameter alternates between ascending and descending
          @order = @sort_by == session[:sort_by_copay] ? -1 : 1
          session[:sort_by_copay] = @order == 1 ? @sort_by : ''
          if @sort_by && @sort_by.length > 0
            @sort_by = @sort_by.strip
            sort_array = []
            qhps.each do |qhp|
              sort_array.push( [qhp, get_visit_cost(qhp,@sort_by)]  )
            end
            sort_array.sort!{|a,b| a[1]*@order <=> b[1]*@order}
            @qhps = sort_array.map{|item| item[0]}
          end
        end

        def export
          render pdf: 'plan_comparison_export',
                 template: 'sponsored_benefits/organizations/plan_design_proposals/plan_comparisons/_export.html.erb',
                 disposition: 'attachment',
                 locals: { qhps: qhps }
        end

        def csv
          @qhps = qhps.each do |qhp|
            if plan_design_proposal.active_benefit_group
              qhp[:total_employee_cost] = plan_design_proposal.active_benefit_group.monthly_employer_contribution_amount(qhp.plan)
            else
              qhp[:total_employee_cost] = 0.00
            end
            # qhp[:total_employee_cost] = ::UnassistedPlanCostDecorator.new(qhp.plan, @hbx_enrollment, session[:elected_aptc], tax_household).total_employee_cost
          end
          respond_to do |format|
            format.csv do
              send_data(::Products::Qhp.csv_for(qhps, visit_types), type: csv_content_type, filename: "comparsion_plans.csv")
            end
          end
        end

        private
        helper_method :plan_design_form, :plan_design_organization, :plan_design_proposal, :visit_types, :qhps

        def plan_design_proposal
          @plan_design_proposal ||= SponsoredBenefits::Organizations::PlanDesignProposal.find(params[:plan_design_proposal_id])
        end

        def plan_design_organization
          @plan_design_organization ||= plan_design_proposal.plan_design_organization
        end

        def requested_plans
          @plans ||= ::Plan.where(:_id => { '$in': params[:plans] } ).map(&:hios_id)
        end

        def qhps
          @qhps ||= ::Products::QhpCostShareVariance.find_qhp_cost_share_variances(requested_plans, plan_design_proposal.effective_date.year, "Health")
        end

        def visit_types
          @visit_types ||= ::Products::Qhp::VISIT_TYPES
        end

        def csv_content_type
          case request.user_agent
            when /windows/i
              'application/vnd.ms-excel'
            else
              'text/csv'
          end
        end
    end
  end
end
