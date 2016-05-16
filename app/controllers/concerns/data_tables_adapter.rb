module DataTablesAdapter
  DataTablesInQuery = Struct.new(:draw, :skip, :take, :search_string)

  def extract_datatable_parameters
    draws = params[:draw]
    start_idx = params[:start].to_i || 0
    window_size = params[:length] || 10
    search_string = nil
    if params[:search]
      search_string = params[:search][:value]
    end
    DataTablesInQuery.new(draws, start_idx, window_size, search_string)
  end
end
