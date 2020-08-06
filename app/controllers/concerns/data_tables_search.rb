# frozen_string_literal: true

module DataTablesSearch
  def sorted_families(order, dt_query, query)
    if order.present?
      order == "asc" ? asc_due_date(query) : desc_due_date(query)
    else
      query.search_and_filter.skip(dt_query.skip).limit(dt_query.take)
    end
  end

  def asc_due_date(query)
    results = query.query_families
                   .sort_with_search_key
                   .sort_with_filter
                   .query_on_min_verification_due_date
                   .sort_asc
                   .skip
                   .take
                   .evaluate.map do |record|
      record["_id"]
    end
    get_families(results)
  end

  def desc_due_date(query)
    results = query.query_families
                   .sort_with_search_key
                   .sort_with_filter
                   .query_on_min_verification_due_date
                   .sort_desc
                   .skip
                   .take
                   .evaluate.map do |record|
      record["_id"]
    end
    get_families(results)
  end

  def get_families(results)
    family_ids = results.map(&:values).map(&:last)
    families = []
    family_ids.each { |_id| families << Family.find(_id)}
    families
  end
end
