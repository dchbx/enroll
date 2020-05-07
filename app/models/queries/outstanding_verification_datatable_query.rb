module Queries
  class OutstandingVerificationDatatableQuery

    attr_reader :search_string, :custom_attributes

    def datatable_search(string)
      @search_string = string
      self
    end

    def initialize(attributes)
      @custom_attributes = attributes
    end

    def person_search search_string
      Family.outstanding_verification_datatable if search_string.blank?
    end

    def build_scope()
      family = Family.outstanding_verification_datatable
      person = Person
      # Arguements passed from documents_uploaded hash: fully_uploaded, partially_uploaded, none, all
      family = family.outstanding_verification_table_scope(@custom_attributes[:documents_uploaded]) if @custom_attributes[:documents_uploaded].present?
      if @custom_attributes[:custom_datatable_date_from].present? & @custom_attributes[:custom_datatable_date_to].present?
         family = family.min_verification_due_date_range(@custom_attributes[:custom_datatable_date_from],@custom_attributes[:custom_datatable_date_to])
      end
      return family if @search_string.blank? || @search_string.length < 2
      person_id = Person.search(@search_string).pluck(:_id)
      #Caution Mongo optimization on chained "$in" statements with same field
      #is to do a union, not an interactionl
      family_scope = family.and('family_members.person_id' => {"$in" => person_id})
      return family_scope if @order_by.blank?
      family_scope.order_by(@order_by)
    end

    def skip(num)
      build_scope.skip(num)
    end

    def limit(num)
      build_scope.limit(num)
    end

    def order_by(var)
      @order_by = var
      self
    end

    def klass
      Family.outstanding_verification_datatable
    end

    def size
      build_scope.count
    end

  end
end
