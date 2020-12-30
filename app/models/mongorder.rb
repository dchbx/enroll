module Mongorder

  def build_search_order_expression(s_field, s_order)
    base_fields = self.default_search_order
    return base_fields unless s_field
    s_order ||= "asc"
    search_dir = (s_order.downcase == "asc") ? 1 : -1
    fields = base_fields.reject { |bf| bf.first.downcase.to_s == s_field.downcase.to_s } 
    fields.unshift([s_field.to_s, search_dir])
  end

  def search(search_string, s_field = nil, s_order = nil, disable_sort = false)
    search_scope = if search_string
                     self.where(
                       self.search_hash(search_string)
                     )
                   else
                     self
                   end

    unless disable_sort
      search_order_expr = build_search_order_expression(s_field, s_order)
      return search_scope.order_by(search_order_expr)
    end

    search_scope
  end

end
