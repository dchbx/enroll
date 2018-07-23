module Queries
  class PlanDesignProposalsQuery
    attr_reader :search_string, :custom_attributes

    def datatable_search(string)
      @search_string = string
      self
    end

    def initialize(attributes)
      @custom_attributes = attributes
      @plan_design_organization = SponsoredBenefits::Organizations::PlanDesignOrganization.find(@custom_attributes[:organization_id])
      @plan_design_proposals = @plan_design_organization.plan_design_proposals
    end

    def build_scope()
      return [] if @plan_design_proposals.nil?
      case @custom_attributes[:quotes]
      when "initial"
        @plan_design_organization.plan_design_proposals.initial
      when "renewing"
        @plan_design_organization.plan_design_proposals.renewing
      when "draft"
        @plan_design_organization.plan_design_proposals.draft
      when "published"
        @plan_design_organization.plan_design_proposals.published
      when "expired"
        @plan_design_organization.plan_design_proposals.expired
      else
        if @search_string.present?
          @plan_design_organization.plan_design_proposals.datatable_search(@search_string)
        else
          @plan_design_proposals
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
      SponsoredBenefits::Organizations::PlanDesignProposal
    end

    def size
      build_scope.count
    end
  end
end
