module Queries
  class PlanDesignOrganizationQuery
    attr_reader :search_string, :custom_attributes

    def datatable_search(string)
      @search_string = string
      self
    end

    def initialize(attributes)
      @custom_attributes = attributes
      @plan_design_organization = SponsoredBenefits::Organizations::PlanDesignOrganization.find_by_owner(@custom_attributes[:profile_id])
    end

    def build_scope()
      return [] if @plan_design_organization.nil?

      case @custom_attributes[:sponsors]
      when "active_sponsors"
        @plan_design_organization.active_sponsors
      when "inactive_sponsors"
        @plan_design_organization.inactive_sponsors
      when "prospect_sponsors"
        @plan_design_organization.prospect_sponsors
      else
        if @search_string.present?
          @plan_design_organization.datatable_search(@search_string)
        else
          @plan_design_organization
        end
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
  end
end
