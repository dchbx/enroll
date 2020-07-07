class Exchanges::ManageSepTypesController < ApplicationController
  include ::DataTablesAdapter
  include ::DataTablesSearch
  include ::Pundit
  include ::SepAll

  layout 'single_column'

  def sep_types_dt
    @selector = params[:scopes][:selector] if params[:scopes].present?
    @datatable = Effective::Datatables::SepTypeDataTable.new(params[:scopes])
    respond_to do |format|
      format.html { render "/exchanges/manage_sep_types/sep_type_datatable.html.erb" }
    end
  end

  def sorting_sep_types
    @sortable =  QualifyingLifeEventKind.all
    respond_to do |format|
      format.html { render "/exchanges/manage_sep_types/sorting_sep_types.html.erb" }
    end
  end
end