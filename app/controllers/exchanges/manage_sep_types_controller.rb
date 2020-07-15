# frozen_string_literal: true

module Exchanges
  class ManageSepTypesController < ApplicationController
    include ::DataTablesAdapter
    include ::DataTablesSearch
    include ::Pundit
    include ::SepAll
    
    layout 'single_column', except: [:new, :edit, :create, :update, :sorting_sep_types]
    layout 'bootstrap_4', only: [:new, :edit, :create, :update, :sorting_sep_types]

    def new
      @qle = Forms::QualifyingLifeEventKindForm.for_new
    end

    def create
      formatted_params = format_create_params(params)
      result = Operations::QualifyingLifeEventKind::Create.new.call(formatted_params)

      respond_to do |format|
        format.html do
          if result.failure?
            @qle = Forms::QualifyingLifeEventKindForm.for_new(result.failure[0].to_h)
            flash[:danger] = result.failure[1].first
            render :new
          else
            flash[:success] = 'A new SEP Type was successfully created.'
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
      result = Operations::QualifyingLifeEventKind::Update.new.call(formatted_params)

      respond_to do |format|
        format.html do
          if result.failure?
            @qle = Forms::QualifyingLifeEventKindForm.for_update(formatted_params)

            flash[:danger] = result.failure[1].first
            render :edit
          else
            flash[:success] = 'The SEP Type was successfully updated.'
            redirect_to sep_types_dt_exchanges_manage_sep_types_path
          end
        end
      end
    end

    def sep_type_to_publish
      # authorize Family, :can_update_ssn? # TODO pundit policy
      @qle = QualifyingLifeEventKind.find(params[:qle_id])
      @row = params[:qle_action_id]
      respond_to do |format|
        format.js { render "sep_type_to_publish"}
      end
    end

    def sep_type_to_expire
      # authorize Family, :can_update_ssn? # TODO pundit policy
      @qle = QualifyingLifeEventKind.find(params[:qle_id])
      @row = params[:qle_action_id]
      respond_to do |format|
        format.js { render "sep_type_to_expire"}
      end
    end

    def publish_sep_type
      begin
        @qle = QualifyingLifeEventKind.find(params[:qle_id])
        if @qle.present? && @qle.may_publish?
          if @qle.publish!
            message = {notice: "Sep Type Published Successfully."}
          else
            message = {notice: "Unable to Publish Sep Type."}
          end
        end
      rescue Exception => e
      message = {error: e.to_s}
      end
      redirect_to exchanges_manage_sep_types_root_path, flash: message
    end

    def expire_sep_type
      begin
        @qle = QualifyingLifeEventKind.find(params[:qle_id])
        end_on = Date.strptime(params["end_on"], "%m/%d/%Y") rescue nil
        if @qle.present? && end_on.present?
          if end_on >= TimeKeeper.date_of_record
            if @qle.may_schedule_expiration?
              @qle.schedule_expiration!(end_on)
              message = {notice: "Expiration Date Set On Sep Type Successfully."}
            end
          else
            if @qle.may_expire?
              @qle.expire!(end_on)
              message = {notice: "Sep Type Expired Successfully."}
            end
          end
        end
      rescue Exception => e
        message = {error: e.to_s}
      end
       redirect_to exchanges_manage_sep_types_root_path, flash: message
    end

    def sep_type_to_publish
      # authorize Family, :can_update_ssn? # TODO pundit policy
      @qle = QualifyingLifeEventKind.find(params[:qle_id])
      @row = params[:qle_action_id]
      respond_to do |format|
        format.js { render "sep_type_to_publish"}
      end
    end

    def sep_type_to_expire
      # authorize Family, :can_update_ssn? # TODO pundit policy
      @qle = QualifyingLifeEventKind.find(params[:qle_id])
      @row = params[:qle_action_id]
      respond_to do |format|
        format.js { render "sep_type_to_expire"}
      end
    end

    def publish_sep_type
      begin
        @qle = QualifyingLifeEventKind.find(params[:qle_id])
        if @qle.present? && @qle.may_publish?
          if @qle.publish!
            message = {notice: "Sep Type Published Successfully."}
          else
            message = {notice: "Unable to Publish Sep Type."}
          end
        end
      rescue Exception => e
      message = {error: e.to_s}
      end
      redirect_to exchanges_manage_sep_types_root_path, flash: message
    end

    def expire_sep_type
      begin
        @qle = QualifyingLifeEventKind.find(params[:qle_id])
        end_on = Date.strptime(params["end_on"], "%m/%d/%Y") rescue nil
        if @qle.present? && end_on.present?
          if end_on >= TimeKeeper.date_of_record
            if @qle.may_schedule_expiration?
              @qle.schedule_expiration!(end_on)
              message = {notice: "Expiration Date Set On Sep Type Successfully."}
            end
          else
            if @qle.may_expire?
              @qle.expire!(end_on)
              message = {notice: "Sep Type Expired Successfully."}
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
        market_kind = params.permit!.to_h['market_kind']
        sort_data = params.permit!.to_h['sort_data']
        sort_data.each do |sort|
          QualifyingLifeEventKind.active.where(market_kind: market_kind, id: sort['id']).update(ordinal_position: sort['position'])
        end
        render json: { message: "Successfully sorted", status: 'success' }, status: :ok
      rescue => e
        render json: { message: "An error occured while sorting", status: 'error' }, status: :internal_server_error
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
  end
end
