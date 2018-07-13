require_dependency "sponsored_benefits/application_controller"

module SponsoredBenefits
  class CensusMembers::PlanDesignCensusEmployeesController < ApplicationController
    include DataTablesAdapter

    before_action :load_plan_design_proposal
    before_action :load_plan_design_census_employee, only: [:show, :edit, :update, :destroy]

    def index
    end

    def show
    end

    def new
      @census_employee = build_census_employee
      if params[:modal].present?
        respond_to do |format|
          format.js { render "upload_employees" }
        end
      end
    end

    def edit
      @census_employee = SponsoredBenefits::CensusMembers::PlanDesignCensusEmployee.find(params.require(:id))
      @census_employee.build_email if @census_employee.email.blank?
      @census_employee.build_address if @census_employee.address.blank?

      respond_to do |format|
        format.js { render "edit" }
      end
    end

    def create
      @plan_design_census_employee = SponsoredBenefits::CensusMembers::PlanDesignCensusEmployee.new(plan_design_employee_params)
      @plan_design_census_employee.benefit_sponsorship_id = @plan_design_proposal.profile.benefit_sponsorships.first.id

      if @plan_design_census_employee.save
        redirect_to :back, :flash => {:success => "Employee record created successfully."}
      else
        redirect_to :back, :flash => {:error => "Unable to create employee record. #{@plan_design_census_employee.errors.full_messages}"}
      end
    end

    def update
      @plan_design_census_employee.update(plan_design_employee_params)

      if plan_design_employee_params[:census_dependents_attributes]
        destroyed_dependent_ids = plan_design_employee_params[:census_dependents_attributes].delete_if{|k,v| v.has_key?("_destroy") }.values.map{|x| x[:id]}
        destroyed_dependent_ids.each do |g|
          if census_dependent = @plan_design_census_employee.census_dependents.find(g)
            census_dependent.delete
          end
        end
      end

      respond_to do |format|
        format.js { render "update" }
      end
    end

    def destroy
      @plan_design_census_employee.destroy

      respond_to do |format|
        format.js { render "delete" }
      end
    end

    def bulk_employee_upload
      @census_employee_import = SponsoredBenefits::Forms::PlanDesignCensusEmployeeImport.new({file: params.require(:file), proposal: @plan_design_proposal})

      respond_to do |format|
        begin
          if @census_employee_import.save
            format.html { redirect_to :back, :flash => { :success => "Roster uploaded successfully."} }
          else
            format.html { redirect_to :back, :flash => { :error => "Roster upload failed."} }
          end
        rescue Exception => e
          format.html { redirect_to :back, :flash => { :error => e.to_s} }
        end
      end
    end

    def export_plan_design_employees
      sponsorship = @plan_design_proposal.profile.benefit_sponsorships[0]
     
      respond_to do |format|
        format.csv { send_data sponsorship.census_employees.to_csv, filename: "#{@plan_design_proposal.plan_design_organization.legal_name.parameterize.underscore}_census_employees_#{TimeKeeper.date_of_record}.csv" }
      end
    end

    def expected_selection
      if params[:ids].present?
        begin
          census_employees = SponsoredBenefits::CensusMembers::PlanDesignCensusEmployee.where(:id.in => params[:ids])
          census_employees.each do |census_employee|
            census_employee.update_attributes(:expected_selection => params[:expected_selection].downcase)
          end
          render json: { status: 200, message: 'successfully submitted the selected Employees participation status' }
        rescue => e
          render json: { status: 500, message: 'An error occured while submitting employees participation status' }
        end
      end
    end

    private

    def load_plan_design_proposal
      @plan_design_proposal = SponsoredBenefits::Organizations::PlanDesignProposal.find(params.require(:plan_design_proposal_id))
    end

    def load_plan_design_census_employee
      @plan_design_census_employee = SponsoredBenefits::CensusMembers::PlanDesignCensusEmployee.find(params.require(:id))
    end

    def build_census_employee
      census_employee = SponsoredBenefits::CensusMembers::PlanDesignCensusEmployee.new
      census_employee.build_address
      census_employee.build_email
      census_employee
    end

    def plan_design_employee_params
      params.require(:census_members_plan_design_census_employee).permit(
       :first_name,
       :middle_name,
       :last_name,
       :name_sfx,
       :dob,
       :ssn,
       :gender,
       :hired_on,
       :is_business_owner,
       address_attributes: [:kind, :address_1, :address_2, :city, :state, :zip],
       email_attributes: [:kind, :address],
       census_dependents_attributes: [:id, :first_name, :middle_name, :last_name, :dob, :employee_relationship, :ssn, :gender, :_destroy])
    end
  end
end
