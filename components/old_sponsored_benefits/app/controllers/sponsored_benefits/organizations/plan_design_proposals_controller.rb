module SponsoredBenefits
  class Organizations::PlanDesignProposalsController < ApplicationController
    include Config::BrokerAgencyHelper
    include DataTablesAdapter
    before_action :load_plan_design_organization, except: [:destroy, :publish, :claim, :show]
    before_action :load_plan_design_proposal, only: [:edit, :update, :destroy, :publish, :show]
    before_action :published_plans_are_view_only, only: [:edit]
    before_action :claimed_quotes_are_view_only, only: [:edit]

    def index
      @datatable = effective_datatable
    end

    def claim
      # TODO FIXME: Raghuram suggested to move this action into employer_profiles_controller.rb in main app as the button exists in the employer portal.
      employer_profile_id = params.fetch(:employer_profile_id, nil)
      employer_profile = EmployerProfile.find(employer_profile_id)

      quote_claim_code = params.fetch(:claim_code, nil).try(:upcase)

      claim_code_status, quote = SponsoredBenefits::Organizations::PlanDesignProposal.claim_code_status?(quote_claim_code)

      error_message = quote.present? ? check_if_county_zip_are_same(quote, employer_profile) : ""

      if error_message.present?
        flash[:error] = error_message
      elsif claim_code_status == "invalid"
        flash[:error] = "No quote matching this code could be found. Please contact your broker representative."
      elsif claim_code_status == "claimed"
        flash[:error] = "Quote claim code already claimed."
      else
        begin
          SponsoredBenefits::Organizations::PlanDesignProposal.build_plan_year_from_quote(employer_profile, quote)
          flash[:notice] = "Code claimed with success. Your Plan Year has been created."
        rescue Exception => e
          flash[:error] = "There was an issue claiming this quote. #{e.to_s}"
        end
      end

      redirect_to main_app.employers_employer_profile_path(employer_profile, tab: "benefits")
    end

    def publish
      if @plan_design_proposal.may_publish?
        @plan_design_proposal.publish!
        flash[:notice] = "Quote Published"
      else
        flash[:error] = "Quote failed to publish.".html_safe
      end
      respond_to do |format|
        format.js { render json: { url: organizations_plan_design_proposal_path(@plan_design_proposal) } }
        format.html { redirect_to organizations_plan_design_proposal_path(@plan_design_proposal) }
      end
    end

    def new
      if @plan_design_organization.employer_profile.present?
        begin
          plan_design_proposal = @plan_design_organization.build_proposal_from_existing_employer_profile
          flash[:success] = "Imported quote and employee information from your client #{@plan_design_organization.employer_profile.legal_name}."
          redirect_to action: :edit, id: plan_design_proposal.id
        rescue Exception => e
          flash[:error] = e.to_s
          @plan_design_proposal = SponsoredBenefits::Forms::PlanDesignProposal.new(organization: @plan_design_organization)
          init_employee_datatable
        end
      else
        @plan_design_proposal = SponsoredBenefits::Forms::PlanDesignProposal.new(organization: @plan_design_organization)
        init_employee_datatable
      end
    end

    def show
      @plan_design_organization = @plan_design_proposal.plan_design_organization
      @benefit_group = @plan_design_proposal.active_benefit_group
      sponsorship = @plan_design_proposal.profile.benefit_sponsorships.first
      @census_employees = sponsorship.census_employees

      if @benefit_group
        @plan = @benefit_group.reference_plan
        @employer_contribution_amount = @benefit_group.monthly_employer_contribution_amount
        @benefit_group_costs = @benefit_group.employee_costs_for_reference_plan
      end
    end

    def edit
      @plan_design_proposal = SponsoredBenefits::Forms::PlanDesignProposal.new(organization: @plan_design_organization, proposal_id: params[:id])
      init_employee_datatable
    end

    def create
      @plan_design_proposal = SponsoredBenefits::Forms::PlanDesignProposal.new({
          organization: @plan_design_organization
        }.merge(plan_design_proposal_params))

      respond_to do |format|
        if @plan_design_proposal.save
          flash[:success] = "Quote information saved successfully."
        else
          flash[:error] = "Quote information save failed."
        end

        format.js
      end
    end

    def update
      @plan_design_proposal = SponsoredBenefits::Forms::PlanDesignProposal.new({
        organization: @plan_design_organization, proposal_id: params[:id]
        }.merge(plan_design_proposal_params))

      respond_to do |format|
        if @plan_design_proposal.save
          flash[:success] = "Quote information updated successfully."
        else
          flash[:error] = "Quote information update failed."
        end

        format.js
      end
    end

    def destroy
      @plan_design_proposal.destroy!
      redirect_to organizations_plan_design_organization_plan_design_proposals_path(@plan_design_proposal.plan_design_organization._id)
    end

    private

    def effective_datatable
      ::Effective::Datatables::PlanDesignProposalsDatatable.new(organization_id: @plan_design_organization._id)
    end

    def load_plan_design_organization
      @plan_design_organization = SponsoredBenefits::Organizations::PlanDesignOrganization.find(params[:plan_design_organization_id])
      broker_agency_profile
    end

    def broker_agency_profile
      @broker_agency_profile = @plan_design_organization.broker_agency_profile
    end

    def load_plan_design_proposal
      proposal_id = params[:id] || params[:plan_design_proposal_id]
      @plan_design_proposal ||= Organizations::PlanDesignProposal.find(proposal_id)
    end

    def plan_design_proposal_params
      params.require(:forms_plan_design_proposal).permit(
        :title,
        :effective_date,
        profile: [
          benefit_sponsorship: [
            :initial_enrollment_period,
            :annual_enrollment_period_begin_month_of_year,
            benefit_application: [
              :effective_period,
              :open_enrollment_period,
            ]
          ]
        ]
        )
    end

    def check_if_county_zip_are_same(quote, employer_profile)
      employer_profile_address = employer_profile.organization.try(:primary_office_location).try(:address)
      if quote.try(:plan_design_organization).try(:office_location_zip) != employer_profile_address.try(:zip) ||
        quote.try(:plan_design_organization).try(:office_location_county) != employer_profile_address.try(:county)
        "Unable to claim quote. The Zip/County information used by this quote does not match your Employer record. Please contact the Broker who provided this quote to you."
      end
    end

    def employee_datatable(sponsorship)
      Effective::Datatables::PlanDesignEmployeeDatatable.new({id: sponsorship.id, scopes: params[:scopes]})
    end

    def init_employee_datatable
      sponsorship = @plan_design_proposal.profile.benefit_sponsorships.first
      @census_employees = sponsorship.census_employees
      @datatable = employee_datatable(sponsorship)
    end

    def published_plans_are_view_only
      if @plan_design_proposal.published?
        redirect_to organizations_plan_design_proposal_path(@plan_design_proposal)
      end
    end

    def claimed_quotes_are_view_only
      if @plan_design_proposal.claimed?
        redirect_to organizations_plan_design_proposal_path(@plan_design_proposal)
      end
    end
  end
end
