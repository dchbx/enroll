# frozen_string_literal: true

require_dependency "sponsored_benefits/application_controller"

module SponsoredBenefits
  class Organizations::GeneralAgencyProfilesController < ApplicationController

    def index
      # Add pundit Authourization
      @form = SponsoredBenefits::Forms::GeneralAgencyManager.for_index(
        action_id: params[:action_id],
        broker_agency_profile_id: params[:broker_agency_profile_id],
        plan_design_organization_id: params[:id]
      )
    end

    def assign
      # Add pundit Authourization
      @form = SponsoredBenefits::Forms::GeneralAgencyManager.for_assign(
        plan_design_organization_ids: JSON.parse(params[:ids].to_s),
        broker_agency_profile_id: params[:broker_agency_profile_id],
        general_agency_profile_id: params[:general_agency_profile_id]
      )
      if @form.assign
        flash[:success] = "Succesfully Assigned General Agency"
      else
        flash[:error] = "Assignment failed: #{@form.errors.full_messages.join(',')}"
      end
      redirect_to sponsored_benefits.employers_organizations_broker_agency_profile_path(id: @form.broker_agency_profile_id)
    end

    def fire
      # Add pundit Authourization
      @form = SponsoredBenefits::Forms::GeneralAgencyManager.for_fire(
        plan_design_organization_ids: params[:ids],
        broker_agency_profile_id: params[:broker_agency_profile_id]
      )
      if @form.fire!
        flash[:notice] = "Succesfully Fired General Agency"
      else
        flash[:error] = "Clear Assignment failed: #{@form.errors.full_messages.join(',')}"
      end
      redirect_to sponsored_benefits.employers_organizations_broker_agency_profile_path(id: @form.broker_agency_profile_id)
    end

    def set_default
      # Add pundit Authourization
      @form = SponsoredBenefits::Forms::GeneralAgencyManager.for_default(
        broker_agency_profile_id: params[:broker_agency_profile_id],
        general_agency_profile_id: params[:general_agency_profile_id]
      )
      flash[:notice] = if @form.set_default!
                         "Setting default general agencies may take a few minutes to update all employers."
                       else
                         "Setting Default General Agency Failed: #{@form.errors.full_messages.join(',')}"
                       end
      redirect_to benefit_sponsors.general_agency_index_profiles_broker_agencies_broker_agency_profiles_path(id: @form.broker_agency_profile_id)
    end

    def clear_default
      # Add pundit Authourization
      @form = SponsoredBenefits::Forms::GeneralAgencyManager.for_clear(
        broker_agency_profile_id: params[:broker_agency_profile_id]
      )
      flash[:notice] = if @form.clear_default!
                         "Clearing default general agencies may take a few minutes to update all employers."
                       else
                         "Clearing Default General Agency Failed: #{@form.errors.full_messages.join(',')}"
                       end
      redirect_to benefit_sponsors.general_agency_index_profiles_broker_agencies_broker_agency_profiles_path(id: @form.broker_agency_profile_id)
    end
  end
end
