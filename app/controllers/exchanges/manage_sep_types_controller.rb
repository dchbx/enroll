# frozen_string_literal: true

module Exchanges
  class ManageSepTypesController < ApplicationController
    include ::DataTablesAdapter
    include ::DataTablesSearch
    include ::Pundit
    include ::SepAll

    layout "single_column"
    layout 'bootstrap_4', only: [:new]

    def new

    end

    def create

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