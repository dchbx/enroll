module SponsoredBenefits
  module Organizations
    class PlanDesignProposals::CarriersController < ApplicationController

      def index
        @carrier_names = ::Organization.load_carriers(
                            primary_office_location: plan_design_organization.primary_office_location,
                            selected_carrier_level: selected_carrier_level,
                            active_year: active_year
                            )
      end

      private
        helper_method :selected_carrier_level, :plan_design_organization, :active_year

        def selected_carrier_level
          @selected_carrier_level ||= params[:selected_carrier_level]
        end

        def plan_design_organization
          @plan_design_organization ||= PlanDesignOrganization.find(params[:plan_design_organization_id])
        end

        def active_year
          params[:active_year]
        end
    end
  end
end
