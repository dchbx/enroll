require_dependency "sponsored_benefits/application_controller"

module SponsoredBenefits
  class Organizations::PlanDesignOrganizationsController < ApplicationController
    include Config::AcaConcern
    include Config::BrokerAgencyHelper

    before_action :load_broker_agency_profile, only: [:new, :create]

    def new
      init_organization
    end

    def create
      old_broker_agency_profile = ::BrokerAgencyProfile.find(params[:broker_agency_id])
      broker_agency_profile = SponsoredBenefits::Organizations::BrokerAgencyProfile.find_or_initialize_broker_profile(old_broker_agency_profile).broker_agency_profile
      broker_agency_profile.plan_design_organizations.new(organization_params.merge(owner_profile_id: old_broker_agency_profile.id))

      if broker_agency_profile.save
        flash[:success] = "Prospect Employer (#{organization_params[:legal_name]}) Added Successfully."
        redirect_to employers_organizations_broker_agency_profile_path(@broker_agency_profile)
      else
        init_organization(organization_params)
        render :new
      end
    end

    def edit
      @organization = SponsoredBenefits::Organizations::PlanDesignOrganization.find(params[:id])

      if @organization.is_prospect?
        get_sic_codes
      else
        flash[:error] = "Editing of Client employer records not allowed"
        redirect_to employers_organizations_broker_agency_profile_path(@organization.broker_agency_profile)
      end
    end

    def update
      pdo = SponsoredBenefits::Organizations::PlanDesignOrganization.find(params[:id])

      if pdo.is_prospect?
        pdo.assign_attributes(organization_params)
        ola = organization_params[:office_locations_attributes]

        if ola.blank?
          flash[:error] = "Prospect Employer must have one Primary Office Location."
          redirect_to employers_organizations_broker_agency_profile_path(pdo.broker_agency_profile)
        elsif pdo.save
          flash[:success] = "Prospect Employer (#{pdo.legal_name}) Updated Successfully."
          redirect_to employers_organizations_broker_agency_profile_path(pdo.broker_agency_profile)
        else
          init_organization(organization_params)
          render :edit
        end
      else
        flash[:error] = "Updating of Client employer records not allowed"
        redirect_to employers_organizations_broker_agency_profile_path(pdo.broker_agency_profile)
      end
    end

    def destroy
      organization = SponsoredBenefits::Organizations::PlanDesignOrganization.find(params[:id])

      if organization.is_prospect?
        if organization.plan_design_proposals.blank?
          organization.destroy
          message = "Prospect Employer Removed Successfully."
        else
          message = "Employer #{organization.legal_name}, has existing quotes.
                                Please remove any quotes for this employer before removing."
        end
        redirect_to employers_organizations_broker_agency_profile_path(organization.broker_agency_profile), status: 303, notice: message
      else
        flash[:error] = "Removing of Client employer records not allowed"
        redirect_to employers_organizations_broker_agency_profile_path(organization.broker_agency_profile), status: 303
      end
    end

  private

    def load_broker_agency_profile
      @broker_agency_profile = ::BrokerAgencyProfile.find(params[:broker_agency_id])
    end

    def init_organization(params={})
      if params.blank?
        @organization = SponsoredBenefits::Forms::PlanDesignOrganizationSignup.new
      else
        @organization = SponsoredBenefits::Forms::PlanDesignOrganizationSignup.new(params)
        @organization.valid?
      end
      get_sic_codes
    end

    def find_broker_agency_profile
      @broker_agency_profile = ::BrokerAgencyProfile.find(params[:plan_design_organization_id])
    end

    def organization_params
      org_params = params.require(:organization).permit(
        :legal_name, :dba, :entity_kind, :sic_code,
        :office_locations_attributes => [
          {:address_attributes => [:kind, :address_1, :address_2, :city, :state, :zip, :county]},
          {:phone_attributes => [:kind, :area_code, :number, :extension]},
          {:email_attributes => [:kind, :address]},
          :is_primary
        ]
      )

      if org_params[:office_locations_attributes].present?
        org_params[:office_locations_attributes].delete_if {|key, value| value.blank?}
      end

      org_params
    end

    def get_sic_codes
      @grouped_options = {}
      ::SicCode.all.group_by(&:industry_group_label).each do |industry_group_label, sic_codes|
        @grouped_options[industry_group_label] = sic_codes.collect{|sc| ["#{sc.sic_label} - #{sc.sic_code}", sc.sic_code]}
      end
    end
  end
end
