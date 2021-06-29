# frozen_string_literal: true

module DataTablesAdapter
  DataTablesInQuery = Struct.new(:draw, :skip, :take, :search_string)

  def extract_datatable_parameters
    draws = params[:draw]
    start_idx = params[:start] || 0
    window_size = params[:length] || 10
    search_string = nil
    search_string = params[:search][:value] if params[:search]
    DataTablesInQuery.new(draws, start_idx.to_i, window_size.to_i, search_string)
  end
end
