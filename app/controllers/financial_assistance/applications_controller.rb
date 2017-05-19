class FinancialAssistance::ApplicationsController < ApplicationController
  include UIHelpers::WorkflowController

  def index
    @existing_applications = Family.find_by(person_id: current_user.person).applications

    # view needs to show existing steps if any exist
    # show link to new application (new_financial_assistance_applcations_path)
  end

  def new
    render 'workflow/step'

    # renders out first step
  end

  def step
    if params.key? :attributes
      attributes = params[:attributes].merge(workflow: { current_step: @current_step.to_i + 1 }) if params[:attributes].present?
      #@model.attributes = survey_params(attributes)
      #@model.save!
      #@current_step = @current_step.next_step
    end

    if params.key?(:step)
      @model.workflow = { current_step: @current_step.to_i }
    else
      @model.workflow = { current_step: @current_step.to_i + 1 }
      @current_step = @current_step.next_step
    end
    @model.save!

    render 'workflow/step'
  end

  private
  def survey_params(attributes)
    attributes.permit!
  end

  def find
    Family.find_by(person_id: current_user.person).applications.find(params[:id]) if params.key?(:id)
  end

  def create
    Family.find_by(person_id: current_user.person).applications.new
  end
end
