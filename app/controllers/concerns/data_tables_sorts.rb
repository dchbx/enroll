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

  def apply_sort(collection, sort, cursor, limit, base_model, scopes, order_by)
    if params[:order]["0"][:column].present?
      if scopes.blank?
        sorted_collection = "#{base_model.capitalize}.offset(cursor).limit(limit).order_by('#{order_by} #{sort.upcase}')"
      else
        sorted_collection = "#{base_model.capitalize}.#{scopes.join{"."}}.offset(cursor).limit(limit).order_by('#{order_by} #{sort.upcase}')"
      end
      collection = eval(sorted_collection)
      return collection
    end
  end

end
