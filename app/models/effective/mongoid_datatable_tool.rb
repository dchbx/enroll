# frozen_string_literal: true

module Effective
  class MongoidDatatableTool
    attr_accessor :table_columns

    delegate :page, :per_page, :search_column, :order_column, :collection_class, :quote_sql, :to => :@datatable

    def initialize(datatable, table_columns)
      @datatable = datatable
      @table_columns = table_columns
    end

    def search_terms
      @search_terms ||= @datatable.search_terms.select { |name, _search_term| table_columns.key?(name) }
    end

    def order_by_column
      sort_column = table_columns[@datatable.order_name]
      @order_by_column ||= table_columns[@datatable.order_name] if sort_column[:sortable]
    end

    def order(collection)
      return collection unless order_by_column.present?

      order_column(collection, order_by_column, @datatable.order_direction, order_by_column[:column])
    end

    def order_column_with_defaults(collection, _table_column, direction, sql_column)
      sql_direction = (direction == :desc ? -1 : 1)
      collection.order_by(sql_column => sql_direction)
    end

    def search(collection)
      collection = collection.send(@datatable.global_search_method, @datatable.global_search_string) unless @datatable.global_search_string.blank?
      search_terms.each do |name, search_term|
        column_search = search_column(collection, table_columns[name], search_term, table_columns[name][:column])
        collection = column_search
      end
      collection
    end

    def search_column_with_defaults(collection, _table_column, _term, _sql_column)
      collection
    end

    def paginate(collection)
      collection.skip((page - 1) * per_page).limit(per_page)
    end
  end
end
