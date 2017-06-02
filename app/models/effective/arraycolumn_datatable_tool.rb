module Effective
  class ArraycolumnDatatableTool
    attr_accessor :table_columns

    delegate :page, :per_page, :search_column, :order_column, :collection_class, :quote_sql, :to => :@datatable

    def initialize(datatable, table_columns, array_columns)
      @datatable = datatable
      @table_columns = table_columns
      array_condition = array_columns
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
      unless collection.kind_of?(Array)
      if !@datatable.global_search_string.blank?
        collection = collection.send(@datatable.global_search_method, @datatable.global_search_string)
      end
      search_terms.each do |name, search_term|
        column_search = search_column(collection, table_columns[name], search_term, table_columns[name][:column])
        collection = column_search
      end
      else
      unless @datatable.global_search_string.blank?
        text = @datatable.global_search_string.downcase
        #if @array_condition
          collection = collection.select do |row|
            collection[0].try(:class) == 'Organization' ? enrollment_search(row,text) : ga_serch(row,text)
            # ga_serch(row,text)
        # end
          end
        end
      end
      collection
    end

    def search_column_with_defaults(collection, table_column, term, sql_column)
      collection
    end

    def paginate(collection)
      result_scope = collection.skip((page - 1) * per_page).limit(per_page)
      unless result_scope.kind_of?(Mongoid::Criteria)
        raise "Expected a type of Mongoid::Criteria, got #{result_scope.class.name} instead."
      end
      result_scope
    end
    def enrollment_search(row,text)
      row.employee_role.person.full_name.try(:downcase).match(text) ||
      row.employee_role.person.ssn.try(:downcase).match(text) || row.benefit_group.title.match(text).try(:downcase) ||
      row.coverage_kind.try(:downcase).match(text) || row.humanized_dependent_summary.to_s.match(text).try(:downcase) ||
      row.plan.carrier_profile.legal_name.to_s.try(:downcase).match(text)  || row.plan.name.to_s.try(:downcase).match(text)
    end
    def ga_serch(row,text)
      row.primary_applicant.person.full_name.try(:downcase).match(text) ||
      row.primary_applicant.person.ssn.try(:downcase).match(text)
    end
  end
end
