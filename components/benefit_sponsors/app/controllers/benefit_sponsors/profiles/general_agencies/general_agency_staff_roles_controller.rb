module BenefitSponsors
  module Profiles
    module GeneralAgencies
      class GeneralAgencyStaffRolesController < ::BenefitSponsors::ApplicationController

        def new
          @staff = BenefitSponsors::Organizations::OrganizationForms::StaffRoleForm.for_new
          set_ie_flash_by_announcement

          respond_to do |format|
            format.html { render 'new', layout: false} if params[:profile_type]
            format.js  { render 'new'}
          end
        end

        def create
          @staff = BenefitSponsors::Organizations::OrganizationForms::StaffRoleForm.for_create(general_agency_staff_params)
          begin
            @status,@result = @staff.save
            unless @staff.is_general_agency_registration_page
              flash[:notice] = "Role added successfully" if @status
              flash[:error] = "Role was not added because " + @result unless @status
            end
          rescue Exception => e
            flash[:error] = "Role was not added because " + e.message
          end
          respond_to do |format|
            format.html  { redirect_to profiles_general_agencies_general_agency_profile_path(id: params[:profile_id])}
            format.js
          end
        end

        def approve
          @staff = BenefitSponsors::Organizations::OrganizationForms::StaffRoleForm.for_approve(general_agency_staff_params)
          authorize @staff
          begin
            @status, @result = @staff.approve
            if @status
              flash[:notice] = "Role approved successfully"
            else
              flash[:error] = "Role was not approved because " + @result
            end
          rescue Exception => e
            flash[:error] = "Role was not approved because " + e.message
          end
          redirect_to profiles_general_agencies_general_agency_profile_path(id: params[:staff][:profile_id])
        end

        def destroy
          @staff = BenefitSponsors::Organizations::OrganizationForms::StaffRoleForm.for_destroy(general_agency_staff_params)
          authorize @staff
          begin
            @status, @result = @staff.destroy
            if @status
              flash[:notice] = "Role removed successfully"
            else
              flash[:error] = "Role was not removed because " + @result
            end
          rescue Exception => e
            flash[:error] = "Role was not removed because " + e.message
          end
          redirect_to profiles_general_agencies_general_agency_profile_path(id: params[:profile_id])
        end

        def search_general_agency
          @staff = BenefitSponsors::Organizations::OrganizationForms::StaffRoleForm.for_general_agency_search(general_agency_staff_params)
          @general_agency_profiles = @staff.general_agency_search
        end

        private

        def general_agency_staff_params
          params[:staff].presence || params[:staff] = {}
          params[:staff].merge!({profile_id: params["staff"]["profile_id"] || params["profile_id"] || params["id"], person_id: params["person_id"], profile_type: params[:profile_type] || "general_agency_staff",
                                  filter_criteria: params.permit(:q), is_general_agency_registration_page: params[:general_agency_registration_page] || params["staff"]["is_general_agency_registration_page"]})
          params[:staff].permit!
        end
      end
    end
  end
end
