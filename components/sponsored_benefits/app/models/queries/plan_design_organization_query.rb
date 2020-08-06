# frozen_string_literal: true

module Queries
  class PlanDesignOrganizationQuery
    attr_reader :search_string, :custom_attributes

    def datatable_search(string)
      @search_string = string
      self
    end

    def initialize(attributes)
      @custom_attributes = attributes
    end

    def build_scope
      return plan_design_organizations if plan_design_organizations.blank?
      collection = plan_design_organizations.send(custom_attributes[:filters]) if custom_attributes[:filters]
      filtered_collection(collection || plan_design_organizations)
    end

    def filtered_collection(collection)
      return collection.datatable_search(search_string) if search_string
      collection
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

    def any?
      build_scope.each do |e|
        return if yield(e)
      end
    end

    def klass
      SponsoredBenefits::Organizations::PlanDesignOrganization
    end

    def size
      build_scope.count
    end

    private

    def plan_design_organizations
      return @plan_design_organizations if defined? @plan_design_organizations
      @plan_design_organizations = broker_agency_plan_design_organizations || general_agency_plan_design_organizations
    end

    def broker_agency_plan_design_organizations
      collection = SponsoredBenefits::Organizations::PlanDesignOrganization.find_by_owner(custom_attributes[:profile_id])
      return collection if collection.present?
    end

    def general_agency_plan_design_organizations
      SponsoredBenefits::Organizations::PlanDesignOrganization.find_by_active_general_agency(custom_attributes[:profile_id])
    end
  end
end
