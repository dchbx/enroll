# frozen_string_literal: true

module Exchanges
  class ManageSepTypesController < ApplicationController
    include ::DataTablesAdapter #TODO: check
    include ::Pundit
    include ::L10nHelper

    before_action :updateable?
    layout 'single_column', except: [:new, :edit, :create, :update, :sorting_sep_types, :clone]
    layout 'bootstrap_4', only: [:new, :edit, :create, :update, :sorting_sep_types, :clone]

    def new
      @qle = Forms::QualifyingLifeEventKindForm.for_new
    end

    def create
      result = EnrollRegistry[:sep_types]{ {params: forms_qualifying_life_event_kind_form_params} }
      respond_to do |format|
        format.html do
          if result.failure?
            @qle = Forms::QualifyingLifeEventKindForm.for_new(result.failure[0].to_h)
            @failure = result.failure
            render :new
          else
            flash[:success] = l10n("controller.manage_sep_type.create_success")
            redirect_to sep_types_dt_exchanges_manage_sep_types_path
          end
        end
      end
    end

    def edit
      @qle = Forms::QualifyingLifeEventKindForm.for_edit(params)
    end

    def update
      result = EnrollRegistry[:sep_types]{ {params: forms_qualifying_life_event_kind_form_params} }

      respond_to do |format|
        format.html do
          if result.failure?
            @qle = Forms::QualifyingLifeEventKindForm.for_update(result.failure[0].to_h)
            @failure = result.failure
            return render :edit
          else
            flash[:success] = l10n("controller.manage_sep_type.#{forms_qualifying_life_event_kind_form_params.to_h['publish'] ? 'publish_success' : 'update_success'}")
          end
        end
      end
      redirect_to sep_types_dt_exchanges_manage_sep_types_path
    end

    def clone
      @qle = Forms::QualifyingLifeEventKindForm.for_clone(params.permit(:id).to_h)
      render :new
    end

    def sep_type_to_expire
      params.permit(:qle_id, :qle_action_id)
      @qle = ::QualifyingLifeEventKind.find(params[:qle_id])
      @row = params[:qle_action_id]
    end

    def expire_sep_type
      @result = EnrollRegistry[:expire_sep_type]{ {params: format_expire_sep_type(params)} }
      @row = params[:qle_action_id]

      if @result.failure?
        @qle = @result.failure[0]
        @qle.assign_attributes({end_on: params[:qualifying_life_event_kind][:end_on]})
        respond_to { |format| format.js { render 'sep_type_to_expire' } }
      else
        flash[:success] = l10n("controller.manage_sep_type.#{@result.success[1]}")
        redirect_to sep_types_dt_exchanges_manage_sep_types_path
      end
    end

    def sep_types_dt
      @datatable = Effective::Datatables::SepTypeDataTable.new
      respond_to do |format|
        format.html {  render '/exchanges/manage_sep_types/sep_type_datatable.html.erb', :layout => 'single_column'}
      end
    end

    def qle_types
      @datatable = Effective::Datatables::SepTypeDataTable.new

      respond_to do |format|
        format.js
      end
    end

    def sorting_sep_types
      @sortable = QualifyingLifeEventKind.all
      respond_to do |format|
        format.html { render "/exchanges/manage_sep_types/sorting_sep_types.html.erb" }
      end
    end

    def sort
      EnrollRegistry[:sort_sep_type]{ {params: params} }
      render json: { message: l10n("controller.manage_sep_type.sort_success"), status: 'success' }, status: :ok
    rescue StandardError
      render json: { message: l10n("controller.manage_sep_type.sort_failure"), status: 'error' }, status: :internal_server_error
    end

    private

    def qle_params
      params.require(:qualifying_life_event_kind_form).permit(
        :start_on,:end_on,:title,:tool_tip,:pre_event_sep_in_days,
        :is_self_attested, :reason, :post_event_sep_in_days,
        :market_kind, :effective_on_kinds, :ordinal_position
      ).to_h.symbolize_keys
    end

    def forms_qualifying_life_event_kind_form_params
      forms_params = params.require(:forms_qualifying_life_event_kind_form).permit(
        [
          "_id",
          "coverage_end_on",
          "coverage_start_on",
          "created_by",
          "date_options_available",
          "end_on",
          "event_kind_label",
          "is_self_attested",
          "is_visible",
          "market_kind",
          "post_event_sep_in_days",
          "pre_event_sep_in_days",
          "published_by",
          "qle_event_date_kind",
          "reason",
          "start_on",
          "title",
          "tool_tip",
          "updated_by",
          "publish",
          "other_reason",
          effective_on_kinds: []
        ]
      )

      forms_params.merge!({_id: params[:id]}) if params.dig(:id)
      forms_params.to_h
    end

    def format_expire_sep_type(params)
      params.merge!({end_on: params[:qualifying_life_event_kind][:end_on],
                     updated_by: params[:qualifying_life_event_kind][:updated_by]})
    end

    def updateable?
      authorize QualifyingLifeEventKind, :can_manage_qles?
    rescue StandardError
      redirect_to root_path, :flash => { :error => l10n("controller.manage_sep_type.not_authorized") }
    end
  end
end
