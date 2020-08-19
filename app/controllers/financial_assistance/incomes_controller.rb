 class FinancialAssistance::IncomesController < ApplicationController

  before_action :set_current_person

  include UIHelpers::WorkflowController
  include NavigationHelper
  include FinancialAssistanceHelper

  before_filter :find_application_and_applicant
  before_filter :load_support_texts, only: [:index, :other]

  def index
    save_faa_bookmark(@person, request.original_url)
    set_admin_bookmark_url
    render layout: 'financial_assistance'
  end

  def other
    save_faa_bookmark(@person, request.original_url)
    set_admin_bookmark_url
    render layout: 'financial_assistance'
  end

  def new
    @model = @applicant.incomes.build
    load_steps
    current_step
    render 'workflow/step', layout: 'financial_assistance'
  end

  def edit
    @income = @applicant.incomes.find params[:id]
    respond_to do |format|
      format.js { render partial: 'financial_assistance/incomes/other_income_form', locals: { income: income } }
    end
  end

  def step
    save_faa_bookmark(@person, request.original_url.gsub(/\/step.*/, "/step/#{@current_step.to_i}"))
    set_admin_bookmark_url
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

  def create
    format_date(params)
    @income = @applicant.incomes.build permit_params(params[:financial_assistance_income])
    if @income.save
      render :create
    else
      head :ok
    end
  end

  def update
    format_date(params)
    @income = @applicant.incomes.find params[:id]
    if @income.update_attributes permit_params(params[:financial_assistance_income])
      render :update
    else
      render head: 'ok'
    end
  end


  def destroy
    @income = @applicant.incomes.find(params[:id])
    @income.destroy!

    head :ok
  end

  private
  def format_date params
    return if params[:financial_assistance_income].blank?
    params[:financial_assistance_income][:start_on] = Date.strptime(params[:financial_assistance_income][:start_on].to_s, "%m/%d/%Y")
    if params[:financial_assistance_income][:end_on].present?
      params[:financial_assistance_income][:end_on] = Date.strptime(params[:financial_assistance_income][:end_on].to_s, "%m/%d/%Y")
    end
  end

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

  def permit_params(attributes)
    return if attributes.blank?
    attributes.permit!
  end

  def load_support_texts
    raw_support_text = YAML.load_file("app/views/financial_assistance/shared/support_text.yml")
    @support_texts = set_support_text_placeholders raw_support_text
  end

  def find
    begin
      FinancialAssistance::Application.find(params[:application_id]).active_applicants.find(params[:applicant_id]).incomes.find(params[:id])
    rescue
      nil
    end
  end
 end
