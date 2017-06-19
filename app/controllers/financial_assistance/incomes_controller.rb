 class FinancialAssistance::IncomesController < ApplicationController

  include UIHelpers::WorkflowController

  before_filter :find_application_and_applicant

  def new
    @model = @applicant.incomes.build
    load_steps
    current_step
    render 'workflow/step'
  end

  def step
    model_name = @model.class.to_s.split('::').last.downcase
    model_params = params[model_name]
    format_date_params model_params

    if params.key?(model_name)
      @model.workflow = { current_step: @current_step.to_i + 1 }
      @current_step = @current_step.next_step if @current_step.next_step.present?
    else
      @model.workflow = { current_step: @current_step.to_i }
    end

    @model.assign_attributes(permit_params(model_params)) if model_params.present?
    update_employer_contact(@model, params) if @model.income_type == job_income_type

    begin
      @model.save!
      if params[:commit] == "Finish"
        flash[:notice] = "Income Added - (#{@model.kind})"
        redirect_to edit_financial_assistance_application_applicant_path(@application, @applicant)
      else
        render 'workflow/step'
      end
    rescue
      flash[:error] = build_error_messages(@model)
      render 'workflow/step'
    end
    
  end

  def destroy
    income = @applicant.incomes.find(params[:id])
    income.destroy!
    flash[:success] = "Income deleted - (#{income.kind})"
    redirect_to edit_financial_assistance_application_applicant_path(@application, @applicant)
  end

  private

  def job_income_type
    FinancialAssistance::Income::JOB_INCOME_TYPE_KIND
  end

  def format_date_params model_params
    model_params["start_on"]=Date.strptime(model_params["start_on"].to_s, "%m/%d/%Y") if model_params.present?
    model_params["end_on"]=Date.strptime(model_params["end_on"].to_s, "%m/%d/%Y") if model_params.present?
  end

  def build_error_messages(model)
    # all_errors = ""
    # all_errors = all_errors + model.errors.full_messages.join(', ') if model.errors.messages.present?
    # all_errors = all_errors + model.employer_address.errors.full_messages.join(', ') if model.employer_address.present? && model.employer_address.errors.messages.present?
    # all_errors = all_errors + model.employer_phone.errors.full_messages.join(', ') if model.employer_phone.present? && model.employer_phone.errors.messages.present?
    # return all_errors
    model.valid? ? nil : model.errors.messages.first.flatten.flatten.join(',').gsub(",", " ").titleize
  end

  def update_employer_contact model, params
    if params[:employer_phone].present?
      @model.build_employer_phone
      params[:employer_phone].merge!(kind: "work") # hack to get pass phone validations
      @model.employer_phone.assign_attributes(permit_params(params[:employer_phone]))
    end
    if params[:employer_address].present?
      @model.build_employer_address
      params[:employer_address].merge!(kind: "work") # hack to get pass phone validations
      @model.employer_address.assign_attributes(permit_params(params[:employer_address]))
    end
  end

  def find_application_and_applicant
    @application = FinancialAssistance::Application.find(params[:application_id])
    @applicant = @application.applicants.find(params[:applicant_id])
  end

  def create
    @application = FinancialAssistance::Application.find(params[:application_id])
    @applicant = @application.applicants.find(params[:applicant_id])
    @model = @applicant.incomes.build
    # @model.build_employer_phone
    # @model.build_employer_address
    # @model
  end

  def permit_params(attributes)
    attributes.permit!
  end

  def find
    begin
      FinancialAssistance::Application.find(params[:application_id]).applicants.find(params[:applicant_id]).incomes.find(params[:id])
    rescue
      nil
    end
  end
end
