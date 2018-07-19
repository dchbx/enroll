module Effective
  class ArraycolumnDatatable < Effective::Datatable
    def global_search_method
      :datatable_searchs
    end

    protected

    def table_tool 
      array_columns = table_columns.select { |_, col| col[:array_column] }.present? ? table_columns.select { |_, col| col[:array_column] }.values.first : []
      @table_tool ||= ArraycolumnDatatableTool.new(self, table_columns.reject { |_, col| col[:array_column] }, array_columns)
    end

    def active_record_collection?
      @active_record_collection ||= false
    end
  end
end
