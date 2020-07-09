# frozen_string_literal: true

module Exchanges
  class ManageSepTypesController < ApplicationController
    include ::DataTablesAdapter
    include ::DataTablesSearch
    include ::Pundit
    include ::SepAll

    layout "single_column"

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
        params['sort_data'].values.each do |data|
          QualifyingLifeEventKind.active.where(market_kind: params[:market_kind], id: data['id']).update(ordinal_position: data['position'])
        end
        render json: { status: 200, message: 'Successfully sorted' }
      rescue => e
        render json: { status: 500, message: 'An error occured while sorting' }
      end
    end
  end
end