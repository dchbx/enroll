# frozen_string_literal: true

# rubocop:disable Metrics/CyclomaticComplexity

# rubocop:disable Metrics/PerceivedComplexity

# rubocop:disable Layout/ConditionPosition

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
      if @custom_attributes[:documents_uploaded].present?
        family = if @custom_attributes[:documents_uploaded] == 'all'
                   family # Keep the full scope
                 elsif @custom_attributes[:documents_uploaded] == 'vlp_fully_uploaded'
                   family.vlp_fully_uploaded
                 elsif
                   family.send(@custom_attributes[:documents_uploaded])
                 end
      end
      if @custom_attributes[:custom_datatable_date_from].present? & @custom_attributes[:custom_datatable_date_to].present?
        family = family.min_verification_due_date_range(@custom_attributes[:custom_datatable_date_from], @custom_attributes[:custom_datatable_date_to], family)
      end
      if @order_by.keys.first == "name"
        family = if @order_by[@order_by.keys.first] == 1
                   family.order_by_name_ascending(family)
                 else
                   family.order_by_name_descending(family)
                 end
      elsif @order_by.keys.first == 'documents_uploaded'
        family = if @order_by[@order_by.keys.first] == 1
                   family.documents_uploaded_ascending
                 else
                   family.documents_uploaded_descending
                 end
      end
      # add other scopes here
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
      return if build_scope.is_a?(Array)
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

# rubocop:enable Metrics/CyclomaticComplexity

# rubocop:enable Metrics/PerceivedComplexity

# rubocop:enable Layout/ConditionPosition


