module DataTablesSearch

  def search_families(search_str, all_families)
    if search_str.blank?
      all_families
    else
      person_ids = Person.search(search_str).pluck(:id)
      all_families.where({
        "family_members.person_id" => {"$in" => person_ids}
      })
    end
  end

  def input_sort_request
    if params[:order].present? && params[:order]["0"][:column] == "4"
      order = params[:order]["0"][:dir]
      return :min_verification_due_date_on_family, order
    elsif params[:order].present? && params[:order]["0"][:column] == "6"
      order = params[:order]["0"][:dir]
      return :review_status, order
    end
    return nil, nil
  end

  def sorted_families(sorted_by, order, families)
    return families if sorted_by.nil?
    if sorted_by == :min_verification_due_date_on_family
      order == "asc" ? families.sort_by(&sorted_by) : families.sort_by(&sorted_by).reverse
    elsif sorted_by == :review_status
      order == "asc" ? families.sort_by(&sorted_by) : families.sort_by(&sorted_by).reverse
    end
  end
end
