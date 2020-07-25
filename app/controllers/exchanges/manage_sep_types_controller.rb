# frozen_string_literal: true

module Exchanges
  class ManageSepTypesController < ApplicationController
    include ::DataTablesAdapter #TODO check
    include ::Pundit
    include ::L10nHelper

    before_action :updateable?
    layout 'single_column', except: [:new, :edit, :create, :update, :sorting_sep_types]
    layout 'bootstrap_4', only: [:new, :edit, :create, :update, :sorting_sep_types]

    def new
      @qle = Forms::QualifyingLifeEventKindForm.for_new
    end

    def create
      formatted_params = format_create_params(params)
      result = Operations::QualifyingLifeEventKind::Create.new.call(formatted_params)
      # result = EnrollRegistry[:sep_types] { formatted_params }
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
      params.permit!
      @qle = Forms::QualifyingLifeEventKindForm.for_edit(params.to_h)
    end

    def update
      formatted_params = format_update_params(params)
      result = Operations::QualifyingLifeEventKind::Create.new.call(formatted_params)

      respond_to do |format|
        format.html do
          if result.failure?
            @qle = Forms::QualifyingLifeEventKindForm.for_update(result.failure[0].to_h)
            @failure = result.failure
            render :edit
          else
            flash[:success] = l10n("controller.manage_sep_type.update_success")
            redirect_to sep_types_dt_exchanges_manage_sep_types_path
          end
        end
      end
    end

    def sep_type_to_publish #pending specs
      @qle = QualifyingLifeEventKind.find(params[:qle_id])
      @row = params[:qle_action_id]
      respond_to do |format|
        format.js { render "sep_type_to_publish"}
      end
    end

    def sep_type_to_expire #pending specs
      params.permit!
      @qle = ::Operations::QualifyingLifeEventKind::Transform.new.call(params.to_h)
      @row = params[:qle_action_id]
      respond_to do |format|
        format.js { render "sep_type_to_expire"}
      end
    end

    def publish_sep_type #pending specs
      begin
        @qle = QualifyingLifeEventKind.find(params[:qle_id])
        if @qle.present? && @qle.may_publish?
          if @qle.publish!
            message = {notice: l10n("controller.manage_sep_type.publish_success")}
          else
            message = {notice: l10n("controller.manage_sep_type.publish_failure")}
          end
        end
      rescue Exception => e
      message = {error: e.to_s}
      end
      redirect_to exchanges_manage_sep_types_root_path, flash: message
    end

    def expire_sep_type  #pending specs
      begin
        @qle = QualifyingLifeEventKind.find(params[:qle_id])
        end_on = Date.strptime(params["end_on"], "%m/%d/%Y") rescue nil
        if @qle.present? && end_on.present?
          if end_on >= TimeKeeper.date_of_record
            if @qle.may_schedule_expiration?
              @qle.schedule_expiration!(end_on)
              message = {notice: l10n("controller.manage_sep_type.enpire_pending_success")}
            end
          else
            if @qle.may_expire?
              @qle.expire!(end_on)
              message = {notice: l10n("controller.manage_sep_type.expire_success")}
            end
          end
        end
      rescue Exception => e
        message = {error: e.to_s}
      end
       redirect_to exchanges_manage_sep_types_root_path, flash: message
    end

    def sep_types_dt
      @datatable = Effective::Datatables::SepTypeDataTable.new
      respond_to do |format|
        format.html { render "/exchanges/manage_sep_types/sep_type_datatable.html.erb" }
      end
    end

    def sorting_sep_types
      @sortable = QualifyingLifeEventKind.all
      respond_to do |format|
        format.html { render "/exchanges/manage_sep_types/sorting_sep_types.html.erb" }
      end
    end

    def sort
      begin
        params.permit!
        Operations::QualifyingLifeEventKind::Sort.new.call(params.to_h)
        render json: { message: l10n("controller.manage_sep_type.sort_success"), status: 'success' }, status: :ok
      rescue => e
        render json: { message: l10n("controller.manage_sep_type.sort_failure"), status: 'error' }, status: :internal_server_error
      end
    end

    private

    def qle_params
      params.require(:qualifying_life_event_kind_form).permit(
        :start_on,:end_on,:title,:tool_tip,:pre_event_sep_in_days,
        :is_self_attested, :reason, :post_event_sep_in_days,
        :market_kind,:effective_on_kinds, :ordinal_position).to_h.symbolize_keys
    end

    def format_create_params(params)
      params.permit!
      params['forms_qualifying_life_event_kind_form'].to_h
    end

    def format_update_params(params)
      params.permit!
      params['forms_qualifying_life_event_kind_form'].merge!({_id: params[:id]})
      params['forms_qualifying_life_event_kind_form'].to_h
    end

    def updateable?
      authorize QualifyingLifeEventKind, :can_manage_qles? rescue redirect_to root_path, :flash => { :error => l10n("controller.manage_sep_type.not_authorized") }
    end
  end
end
