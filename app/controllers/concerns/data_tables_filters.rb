module DataTablesFilters

  def set_filter
    if params[:filters].present?
      filter = params[:filters]
    end
  end

  def apply_filter(collection, sort, cursor, limit, base_model, filters)
    filtered_collection = "#{base_model.capitalize}.#{filters.join(".")}.offset(cursor).limit(limit)"
    collection = eval(filtered_collection)
    return collection
  end

end
