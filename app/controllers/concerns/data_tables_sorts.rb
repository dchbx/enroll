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

  module VerificationsIndexSorts
    def sort_verifications_index_columns(families, sort)
      if params[:order]["0"][:column].present?
        column = params[:order]["0"][:column]
        order_by = (params[:columns][column][:data])

        case order_by
        when "last_name"
          order_by = "_id"
        when "first_name"
          order_by = "_id"
        end

        order_by = order_by.to_sym

        if sort == "asc"
          families = families.order_by(order_by.asc)
        else
          families = families.order_by(order_by.desc)
        end

        return families

      end
    end
  end
end
