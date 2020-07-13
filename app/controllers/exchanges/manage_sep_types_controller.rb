# frozen_string_literal: true

module Exchanges
  class ManageSepTypesController < ApplicationController
    include ::DataTablesAdapter
    include ::DataTablesSearch
    include ::Pundit
    include ::SepAll

   layout "single_column"
   layout 'bootstrap_4', only: [:new, :sorting_sep_types]

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
        render json: { message: "Successfully sorted", status: 'success' }, status: :ok
      rescue => e
        render json: { message: "An error occured while sorting", status: 'error' }, status: :internal_server_error
      end
    end
  end
end
