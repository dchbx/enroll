module Effective
  class MongoidDatatable < Effective::Datatable
    def global_search_method
      :datatable_search
    end

    protected

    def table_tool 
      @table_tool ||= MongoidDatatableTool.new(self, table_columns.reject { |_, col| col[:array_column] })
    end

    def active_record_collection?
      @active_record_collection ||= true
    end
  end
end
