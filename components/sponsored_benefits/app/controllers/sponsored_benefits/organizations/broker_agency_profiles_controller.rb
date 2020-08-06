# frozen_string_literal: true

require_dependency "sponsored_benefits/application_controller"

module SponsoredBenefits
  class Organizations::BrokerAgencyProfilesController < ApplicationController
    include DataTablesAdapter
    before_action :find_profile, :general_agency_profiles, only: [:employers]

    def employers
      # This should be index action in plan design organizations controller
      @datatable = klass.new(profile_id: @profile._id)
    end

    private

    def find_profile
      @profile = BenefitSponsors::Organizations::BrokerAgencyProfile.find(params[:id]) || BenefitSponsors::Organizations::GeneralAgencyProfile.find(params[:id])
      @provider = provider
    end

    def general_agency_profiles
      return @general_agency_profiles if defined? @general_agency_profiles
      @general_agency_profiles = BenefitSponsors::Organizations::GeneralAgencyProfile.all
    end

    def klass
      if is_profile_general_agency?
        ::Effective::Datatables::GeneralAgencyPlanDesignOrganizationDatatable
      else
        ::Effective::Datatables::BrokerAgencyPlanDesignOrganizationDatatable
      end
    end
  end
end
