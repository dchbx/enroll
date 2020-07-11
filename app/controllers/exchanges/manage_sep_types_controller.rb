# frozen_string_literal: true

module Exchanges
  class ManageSepTypesController < ApplicationController
    include ::DataTablesAdapter
    include ::DataTablesSearch
    include ::Pundit
    include ::SepAll

    layout "single_column", except: [:new, :sorting_sep_types]
    layout 'bootstrap_4', only: [:new, :sorting_sep_types]

    def new

    end

    def create

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
      @selector = params[:scopes][:selector] if params[:scopes].present?
      @datatable = Effective::Datatables::SepTypeDataTable.new(params[:scopes])
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
        flash[:success] = 'Successfully sorted'
      rescue => e
        flash[:danger] = 'An error occured while sorting'
      end
    end
  end
end