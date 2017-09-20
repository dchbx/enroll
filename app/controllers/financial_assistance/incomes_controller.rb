 class FinancialAssistance::IncomesController < ApplicationController

  before_action :set_current_person

  include UIHelpers::WorkflowController
  include NavigationHelper

  before_filter :find_application_and_applicant

  def index
    save_faa_bookmark(@person, request.original_url)
    render layout: 'financial_assistance'
  end

  def new
    @model = @applicant.incomes.build
    load_steps
    current_step
    render 'workflow/step', layout: 'financial_assistance'
  end

  def step
    save_faa_bookmark(@person, request.original_url.gsub(/\/step.*/, "/step/#{@current_step.to_i}"))
    flash[:error] = nil
    model_name = @model.class.to_s.split('::').last.downcase
    model_params = params[model_name]
    format_date_params model_params if model_params.present?

    @model.assign_attributes(permit_params(model_params)) if model_params.present?
    update_employer_contact(@model, params) if @model.income_type == job_income_type

    if params.key?(model_name)
      if @model.save(context: "step_#{@current_step.to_i}".to_sym)
        @current_step = @current_step.next_step if @current_step.next_step.present?
        if params.key? :last_step
          @model.update_attributes!(workflow: { current_step: 1 })
          flash[:notice] = "Income Added - (#{@model.kind})"
          redirect_to financial_assistance_application_applicant_incomes_path(@application, @applicant)
        else
          @model.update_attributes!(workflow: { current_step: @current_step.to_i })
          render 'workflow/step', layout: 'financial_assistance'
        end
      else
        @model.workflow = { current_step: @current_step.to_i }
        flash[:error] = build_error_messages(@model)
        render 'workflow/step', layout: 'financial_assistance'
      end
    else
      render 'workflow/step', layout: 'financial_assistance'
    end
  end

  def destroy
    income = @applicant.incomes.find(params[:id])
    income.destroy!
    flash[:success] = "Income deleted - (#{income.kind})"
    redirect_to financial_assistance_application_applicant_incomes_path(@application, @applicant)
  end

  private

  def job_income_type
    FinancialAssistance::Income::JOB_INCOME_TYPE_KIND
  end

  def format_date_params model_params
    model_params["start_on"]=Date.strptime(model_params["start_on"].to_s, "%m/%d/%Y") if model_params.present?
    model_params["end_on"]=Date.strptime(model_params["end_on"].to_s, "%m/%d/%Y") if model_params.present? && model_params["end_on"].present?
  end

  def build_error_messages(model)
    model.valid?("step_#{@current_step.to_i}".to_sym) ? nil : model.errors.full_messages.join("<br />")
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
    @applicant = @application.active_applicants.find(params[:applicant_id])
  end

  def create
    @application = FinancialAssistance::Application.find(params[:application_id])
    @applicant = @application.active_applicants.find(params[:applicant_id])
    @model = @applicant.incomes.build
  end

  def permit_params(attributes)
    attributes.permit!
  end

  def find
    begin
      FinancialAssistance::Application.find(params[:application_id]).active_applicants.find(params[:applicant_id]).incomes.find(params[:id])
    rescue
      nil
    end
  end
 end
