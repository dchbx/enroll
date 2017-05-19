class SurveysController < ApplicationController
  include UIHelpers::WorkflowController

  def new
    render 'workflow/step'
  end

  def step
    attributes = {}
    # TODO
    # Valiation of the parameters can be done here

    # Saving all the form parameters of a single page as 1 field in database.
    attributes[:form_params] = params
    attributes[:workflow] = {current_step: @current_step.to_i + 1}
    
    @model.attributes = attributes
    @model.save!

    # Calling Module methods in order to Update the current page.
    find_or_create
    current_step

    # redirecting to new action, in order to load another page.
    redirect_to action: 'new'
  end

  private
  def find
    Survey.first
  end

  def create
    Survey.new
  end
end
