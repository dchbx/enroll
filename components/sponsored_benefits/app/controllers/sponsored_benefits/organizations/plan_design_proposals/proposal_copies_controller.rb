module SponsoredBenefits
  module Organizations
    class PlanDesignProposals::ProposalCopiesController < ApplicationController

      def create
        new_plan_design_proposal = SponsoredBenefits::Forms::PlanDesignProposal.new({ organization: plan_design_organization }.merge(plan_design_form.to_h))
        existing_roster = SponsoredBenefits::CensusMembers::PlanDesignCensusEmployee.find_by_benefit_sponsor(plan_design_form.proposal.profile.benefit_sponsorships.first)

        if new_plan_design_proposal.save
          proposal = SponsoredBenefits::Organizations::PlanDesignProposal.find(new_plan_design_proposal.proposal.id)
          sponsorship = proposal.profile.benefit_sponsorships.first
          assign_benefit_group(sponsorship: sponsorship, old_sponsorship: plan_design_form.proposal.profile.benefit_sponsorships.first)
          assign_roster_employees(sponsorship: sponsorship, roster: existing_roster)

          proposal.plan_design_organization.save!
          flash[:success] = "Proposal successfully copied"
        else
          flash[:error] = "Something went wrong"
        end
        response_url = edit_organizations_plan_design_organization_plan_design_proposal_path(plan_design_organization, new_plan_design_proposal.proposal.id)
        respond_to do |format|
          format.html { redirect_to response_url }
          format.js { render json: { url: response_url }.to_json, content_type: 'application/json' }
        end
      end

      private
      helper_method :plan_design_form, :plan_design_organization, :plan_design_proposal

      def assign_roster_employees(sponsorship:, roster:)
        roster.each do |employee|
          census_employee = SponsoredBenefits::CensusMembers::PlanDesignCensusEmployee.new.tap do |ce|
            ce.first_name = employee.first_name
            ce.last_name = employee.last_name
            ce.gender = employee.gender
            ce.ssn = employee.ssn
            ce.dob = employee.dob
            employee.census_dependents.each do |dependent|
              new_dependent = SponsoredBenefits::CensusMembers::CensusDependent.new.tap do |dep|
                dep.first_name = dependent.first_name
                dep.last_name = dependent.last_name
                dep.gender = dependent.gender
                dep.employee_relationship = dependent.employee_relationship
                dep.dob = dependent.dob
              end
              ce.census_dependents << new_dependent
            end
            ce.address = employee.address
            ce.email = employee.email
            ce.benefit_sponsorship_id = sponsorship.id
          end
          census_employee.save!
        end
      end

      def assign_benefit_group(sponsorship:, old_sponsorship:)
        old_application = old_sponsorship.benefit_applications.first
        return if old_application.benefit_groups.empty?
        bg = old_application.benefit_groups.first
        new_application = sponsorship.benefit_applications.first

        new_bg = new_application.benefit_groups.build({
          title: bg.title,
          reference_plan_id: bg.reference_plan_id,
          plan_option_kind: bg.plan_option_kind,
          elected_plans: bg.elected_plans
        })

        bg.composite_tier_contributions.each do |contribution|
          new_bg.composite_tier_contributions << contribution.clone
        end
        bg.relationship_benefits.each do |rb|
          new_bg.relationship_benefits << rb.clone
        end

        new_bg.estimate_composite_rates
        new_application.benefit_sponsorship.benefit_sponsorable.save!
      end

      def plan_design_proposal
        @plan_design_proposal ||= SponsoredBenefits::Organizations::PlanDesignProposal.find(params[:plan_design_proposal_id])
      end

      def plan_design_organization
        @plan_design_organization ||= plan_design_proposal.plan_design_organization
      end

      def plan_design_form
        SponsoredBenefits::Forms::PlanDesignProposal.new(organization: plan_design_organization, proposal_id: params[:plan_design_proposal_id])
      end
    end
  end
end
