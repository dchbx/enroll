# frozen_string_literal: true

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

    def person_search(search_string)
      Family.outstanding_verification_datatable if search_string.blank?
    end

    def build_scope
      family = Family.outstanding_verification_datatable
      person = Person
      family = family.send(@custom_attributes[:documents_uploaded]) if @custom_attributes[:documents_uploaded].present?
      if @custom_attributes[:custom_datatable_date_from].present? & @custom_attributes[:custom_datatable_date_to].present?
        family = family.min_verification_due_date_range(@custom_attributes[:custom_datatable_date_from],@custom_attributes[:custom_datatable_date_to])
      end
      #add other scopes here
      return family if @search_string.blank? || @search_string.length < 2
      person_id = build_people_id_criteria(@search_string)
      #Caution Mongo optimization on chained "$in" statements with same field
      #is to do a union, not an interactionl
      family_scope = family.and('family_members.person_id' => {"$in" => person_id})
      return family_scope if @order_by.blank?
      family_scope.order_by(@order_by)
    end

    def build_people_id_criteria(s_string)
      clean_str = s_string.strip

      if clean_str =~ /[a-z]/i
        Person.collection.aggregate([
                                      {"$match" => {
                                        "$text" => {"$search" => clean_str}
                                      }.merge(Person.search_hash(clean_str))},
                                      {"$project" => {"first_name" => 1, "last_name" => 1, "full_name" => 1}},
                                      {"$sort" => {"last_name" => 1, "first_name" => 1}},
                                      {"$project" => {"_id" => 1}}
                                    ], {allowDiskUse: true}).map do |rec|
          rec["_id"]
        end
      else
        Person.search(s_string, nil, nil, true).pluck(:_id)
      end
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
