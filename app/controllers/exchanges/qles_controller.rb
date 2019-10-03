# frozen_string_literal: true

class Exchanges::QlesController < ApplicationController
  # TODO: Determine which need the Pundit before_action
  before_action :can_add_custom_qle?, only: %i[
    manage
    new
    create
    edit
    update
    deactivation_form
    deactivate
  ]
  skip_before_action :verify_authenticity_token, only: %i[deactivate create update]
  layout 'single_column'

  def manage
    set_qles_to_manage
  end

  def question_flow
    set_qle_and_attributes
    attrs = { market_kind: params.dig(:market_kind) }
    redirect_to question_flow_exchanges_qle_path(@qle, attrs)
  end

  def deactivation_form
    set_qle_and_attributes
  end

  def deactivate
    result = Admin::QleKinds::DeactivateService.call(
      current_user,
      params.require("data").permit!.to_hash
    )
    if result.success?
      flash[:notice] = "Successfully deactivated Qualifying Life Event Kind."
    else
      flash[:error] = "Unable to deactivate Qualifying Life Event Kind."
    end
    respond_to do |format|
      format.json { head :no_content, :location => manage_exchanges_qles_path }
    end
  end

  def edit
    set_qle_and_attributes
    verify_qle_kind_inactive
  end

  def update
    set_qle_and_attributes
    verify_qle_kind_inactive
    result = Admin::QleKinds::UpdateService.call(current_user, params.require("data").permit!.to_hash)
    if result.success?
      flash[:notice] = "Successfully updated Qualifying Life Event Kind."
    else
      flash[:error] = "Unable to update Qualifying Life Event Kind."
    end
    render json: {next_url: manage_exchanges_qles_path}
  end

  def sorting_order
    set_sortable_qles
  end

  def new
    set_new_qle_and_questions
  end

  def create
    result = Admin::QleKinds::CreateService.call(
      current_user,
      params.require("data").permit!.to_hash
    )
    if result.success?
      flash[:notice] = "Successfully created Qualifying Life Event Kind."
    else
      flash[:error] = "Unable to create Qualifying Life Event Kind."
    end
    render json: {next_url: manage_exchanges_qles_path}
  end

  private

  # The QualifyingLifeEventKind.editable scope displaying editable QLE Kinds on the manage page verifies that
  # is_active is set to false. Add this as an extra precaution to not allow access to the edit/update actions by accidnet.
  def verify_qle_kind_inactive
    msg = "Unable to modify active Qualifying life Event Kind."
    redirect_to(manage_exchanges_qles_path, flash: { error: msg }) if @qle.is_active == true
  end

  def can_add_custom_qle?
    redirect_to(root_path, :flash => { :error => "Access not allowed" }) unless authorize(HbxProfile, :can_add_custom_qle?)
  end

  def set_sortable_qles
    @qle = QualifyingLifeEventKind.all
  end

  def set_qles_to_manage
    # TODO: Fix these scopes, probably hide them behind a JSON serializer
    # TODO: Consider adding a blank option, and then assure in the qle_kind_wizard
    # that the submit button doesn't work unless a option with a value is selected.
    @editable_qles = QualifyingLifeEventKind.editable
    @deactivatable_qles = QualifyingLifeEventKind.not_set_for_deactivation
  end

  def set_new_qle_and_questions
    @qle = QualifyingLifeEventKind.new
    @qle.custom_qle_questions.build
  end

  def set_qle_and_attributes
    @qle = QualifyingLifeEventKind.find(params[:id])
    @qle_form_attributes = @qle.attributes
  end

  def permitted_params
    params.permit!.to_h
  end
end
