module Effective
  class MongoidDatatableTool
    attr_accessor :table_columns

    delegate :page, :per_page, :search_column, :order_column, :collection_class, :quote_sql, :to => :@datatable

    def initialize(datatable, table_columns)
      @datatable = datatable
      @table_columns = table_columns
    end

    def search_terms
      @search_terms ||= @datatable.search_terms.select { |name, search_term| table_columns.key?(name) }
    end

    def order_by_column
      @order_by_column ||= table_columns[@datatable.order_name]
    end

    def order(collection)
      return collection unless order_by_column.present?

      column_order = order_column(collection, order_by_column, @datatable.order_direction, order_by_column[:column])
      column_order
    end

    def order_column_with_defaults(collection, table_column, direction, sql_column)

      sql_direction = (direction == :desc ? -1 : 1)
      collection.order_by(sql_column => sql_direction)
    end

    def search(collection)
      if !@datatable.global_search_string.blank?
        collection = collection.send(@datatable.global_search_method, @datatable.global_search_string)
      end
      search_terms.each do |name, search_term|
        column_search = search_column(collection, table_columns[name], search_term, table_columns[name][:column])
        collection = column_search
      end
      collection
    end

    def search_column_with_defaults(collection, table_column, term, sql_column)
      collection
    end

    def paginate(collection)
      result_scope = collection.skip((page - 1) * per_page).limit(per_page)
      result_scope
    end
  end
end
