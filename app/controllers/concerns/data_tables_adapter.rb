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

  def apply_sort_or_filter(collection, offset, limit)
    base_model = params[:base_model]
    order_by = params[:order_by] if params[:order_by].present?
    custom_order_by = params[:custom_order_by] if params[:custom_order_by].present?
    scopes = params[:scopes] if params[:scopes].present?
    scopes = [] if params[:scopes].blank?
    sort_direction = set_sort_direction if order_by.present? || custom_order_by.present? || params[:custom_sort] == true
    collection = apply_sort(collection, sort_direction, offset, limit, base_model, scopes, order_by, custom_order_by) if sort_direction.present?
    filters = params[:filters] if params[:filters].present?
    filter = set_filter if filters.present?
    collection = apply_filter(collection, sort_direction, offset, limit, base_model, filters) if filter.present?
    return collection
  end

end
