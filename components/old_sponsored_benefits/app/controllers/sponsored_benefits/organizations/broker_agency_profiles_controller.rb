require_dependency "sponsored_benefits/application_controller"

module SponsoredBenefits
  class Organizations::BrokerAgencyProfilesController < ApplicationController
    include Config::AcaConcern
    include DataTablesAdapter

    before_action :find_broker_agency_profile, only: [:employers]

    def employers
      @datatable = ::Effective::Datatables::BrokerAgencyEmployerDatatable.new(profile_id: @broker_agency_profile._id)
    end

  private

    def find_broker_agency_profile
      @broker_agency_profile = ::BrokerAgencyProfile.find(params[:id])
    end
  end
end