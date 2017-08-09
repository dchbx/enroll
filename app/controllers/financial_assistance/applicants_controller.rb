class FinancialAssistance::ApplicantsController < ApplicationController

  before_action :set_current_person

  include UIHelpers::WorkflowController
  include FinancialAssistanceHelper

  before_filter :find, :find_application, :except => [:age_of_applicant, :primary_applicant_has_spouse] #except the ajax requests


  def edit
    @applicant = @application.applicants.find(params[:id])
    render layout: 'financial_assistance'
  end

  def other_questions
    @applicant = @application.applicants.find(params[:id])
    render layout: 'financial_assistance'
  end

  def save_questions
    format_date_params params[:financial_assistance_applicant] if params[:financial_assistance_applicant].present?
    @applicant = @application.applicants.find(params[:id])
    @applicant.assign_attributes(permit_params(params[:financial_assistance_applicant])) if params[:financial_assistance_applicant].present?
    if @applicant.save(context: :other_qns)
      redirect_to edit_financial_assistance_application_path(@application)
    else
      @applicant.save(validate: false)
      @applicant.valid?(:other_qns)
      flash[:error] = build_error_messages_for_other_qns(@applicant)
      redirect_to other_questions_financial_assistance_application_applicant_path(@application, @applicant)
    end
  end

  def step
    flash[:error] = nil
    model_name = @model.class.to_s.split('::').last.downcase
    model_params = params[model_name]
    @model.clean_conditional_params(model_params) if model_params.present?
    @model.assign_attributes(permit_params(model_params)) if model_params.present?

    if params.key?(model_name)
      if @model.save(context: "step_#{@current_step.to_i}".to_sym)
        @applicant.reload
        @application.reload
        @current_step = @current_step.next_step if @current_step.next_step.present?
        if params.key? :last_step
          @model.update_attributes!(workflow: { current_step: 1 })
          redirect_to find_applicant_path(@application, @applicant)
        else
          @model.update_attributes!(workflow: { current_step: @current_step.to_i })
          render 'workflow/step', layout: 'financial_assistance'
        end
      else
        @model.assign_attributes(workflow: { current_step: @current_step.to_i })
        @model.save!(validate: false)
        flash[:error] = build_error_messages(@model)
        render 'workflow/step', layout: 'financial_assistance'
      end
    else
      render 'workflow/step', layout: 'financial_assistance'
    end
  end

  def age_of_applicant
    applicant = FinancialAssistance::Application.find(params[:application_id]).applicants.find(params[:applicant_id])
    render :text => "#{applicant.age_of_the_applicant}"
  end

  def primary_applicant_has_spouse
    has_spouse =  @person.person_relationships.where(kind: 'spouse').first.present? ? 'true' : 'false'
    render :text => "#{has_spouse}"
  end

  private

  def format_date_params model_params
    model_params["pregnancy_due_on"]=Date.strptime(model_params["pregnancy_due_on"].to_s, "%m/%d/%Y") if model_params["pregnancy_due_on"].present?
    model_params["pregnancy_end_on"]=Date.strptime(model_params["pregnancy_end_on"].to_s, "%m/%d/%Y") if model_params["pregnancy_end_on"].present?
    model_params["student_status_end_on"]=Date.strptime(model_params["student_status_end_on"].to_s, "%m/%d/%Y") if model_params["student_status_end_on"].present?
  end

  def build_error_messages(model)
    model.valid?("step_#{@current_step.to_i}".to_sym) ? nil : model.errors.messages.first[1][0].titleize
  end

  def build_error_messages_for_other_qns(model)
    model.valid?(:other_qns) ? nil : model.errors.messages.first[1][0].titleize
  end

  def find_application
    @application = FinancialAssistance::Application.find(params[:application_id])
  end

  def find
    @applicant = FinancialAssistance::Application.find(params[:application_id]).applicants.find(params[:id])
  end

  def permit_params(attributes)
    attributes.permit!
  end
end
