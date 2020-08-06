# frozen_string_literal: true

module SponsoredBenefits
  module Organizations
    class PlanDesignProposals::CarriersController < ApplicationController
      before_action :load_broker_agency_profile, only: [:index]

      def index
        @carrier_names = ::Organization.load_carriers(
          primary_office_location: plan_design_organization.primary_office_location,
          selected_carrier_level: selected_carrier_level,
          active_year: active_year,
          kind: kind
        )
      end

      private

      helper_method :selected_carrier_level, :plan_design_organization, :active_year, :kind

      def selected_carrier_level
        @selected_carrier_level ||= params[:selected_carrier_level]
      end

      def plan_design_organization
        @plan_design_organization ||= PlanDesignOrganization.find(params[:plan_design_organization_id])
      end

      def active_year
        params[:active_year] || Timekeeper.date_of_record.year
      end

      def kind
        params[:kind]
      end

      def load_broker_agency_profile
        @plan_design_organization = PlanDesignOrganization.find(params[:plan_design_organization_id])
        @broker_agency_profile = @plan_design_organization.broker_agency_profile
        @provider = @broker_agency_profile.primary_broker_role.person
      end
    end
  end
end
