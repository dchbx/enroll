module DataTablesSorts

  def set_sort_direction
    if params[:order].present?
      if params[:order]["0"].present?
        if params[:order]["0"][:dir].present?
          return params[:order]["0"][:dir]
        end
      end
    end
  end

  def apply_sort(collection, sort, cursor, limit, base_model, scopes, order_by, custom_order_by_array)
    if params[:start_on].present? && params[:end_on].present?
      start_on = Date.strptime(params[:start_on], "%m/%d/%Y")
      end_on = Date.strptime(params[:end_on], "%m/%d/%Y")
      custom_date_scope, other_scopes = scopes.partition {|scope| scope == scopes.last}
      custom_date_scope = custom_date_scope.first
    end
    if params[:month_filter] == "true"
      month_scopes, regular_scopes = scopes.partition {|scope| scope =~ /\d/ }
      new_month_scopes = []
      month_scopes.each do |scope|
        begin_params = (scope.index('(')) - 1
        scope = "#{scope[0..begin_params]}"+"(Date.strptime('#{scope.to_date.to_s}', '%d/%m/%Y'))"
        new_month_scopes << scope
      end
    scopes = regular_scopes + new_month_scopes
    end
    if params[:order]["0"][:column].present?
      if scopes.blank?
        sorted_collection = "#{base_model.capitalize}.order_by(:'#{order_by}'.#{sort.downcase})"
      else
        if params[:start_on].present? && params[:end_on].present?
          sorted_collection = "#{base_model.capitalize}.#{other_scopes.join(".")}.#{custom_date_scope}(start_on, end_on)"
          sorted_collection = "#{base_model.capitalize}.#{other_scopes.join(".")}.#{custom_date_scope}(start_on, end_on).order_by(:'#{order_by}'.#{sort.downcase})" if params[:order_by].present?
        else
          sorted_collection = "#{base_model.capitalize}.#{scopes.join(".")}"
          sorted_collection = "#{base_model.capitalize}.#{scopes.join(".")}.order_by(:'#{order_by}'.#{sort.downcase})" if params[:order_by].present?
        end
      end
      collection = eval(sorted_collection)
      return collection
    end
  end

end
