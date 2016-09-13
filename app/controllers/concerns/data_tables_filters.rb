module DataTablesFilters

  def set_filter
    if params[:filters].present?
      filter = params[:filters]
    end
  end

  def apply_filter(collection, sort, cursor, limit, base_model, filters)
    if params[:start_on].present? && params[:end_on].present?
      start_on = Date.strptime(params[:start_on], "%m/%d/%Y")
      end_on = Date.strptime(params[:end_on], "%m/%d/%Y")
      custom_date_filter, other_filters = filters.partition {|filter| filter == filters.last}
      custom_date_filter = custom_date_filter.first
      filtered_collection = "#{base_model.capitalize}.#{other_filters.join(".")}.#{custom_date_filter}(start_on, end_on)"
    else
      if params[:month_filter] == "true"
        month_filters, regular_filters = filters.partition {|filter| filter =~ /\d/ }
        new_month_filters = []
        month_filters.each do |filter|
          begin_params = (filter.index('(')) - 1
          filter = "#{filter[0..begin_params]}"+"(Date.strptime('#{filter.to_date.to_s}', '%d/%m/%Y'))"
          new_month_filters << filter
        end
        filters = regular_filters + new_month_filters
        filtered_collection = "#{base_model.capitalize}.#{filters.join(".")}"
      else
        filtered_collection = "#{base_model.capitalize}.#{filters.join(".")}"
      end
    end
    collection = eval(filtered_collection)
    return collection
  end

end
