# frozen_string_literal: true

module BenefitSponsors
  module Profiles
    module Employers
      class EmployerStaffRolesController < ::BenefitSponsors::ApplicationController

        include Pundit

        def new
          @staff = BenefitSponsors::Organizations::OrganizationForms::StaffRoleForm.for_new
          respond_to do |format|
            format.html
            format.js
          end
        end

        def create
          @staff = BenefitSponsors::Organizations::OrganizationForms::StaffRoleForm.for_create(staff_params)
          authorize @staff
          begin
            @status, @result = @staff.save
            if @status
              flash[:notice] = "Role added sucessfully"
            else
              flash[:error] = ('Role was not added because ' + @result)
            end
          rescue Exception => e
            flash[:error] = e.message
          end
          redirect_to edit_profiles_registration_path(id: staff_params[:profile_id])
        end

        #new person registered with existing organization is pending for staff role approval
        #below action is triggered from employer to approve for staff role
        def approve
          @staff = BenefitSponsors::Organizations::OrganizationForms::StaffRoleForm.for_approve(staff_params)
          authorize @staff
          @status, @result = @staff.approve
          if @status
            flash[:notice] = 'Role is approved'
          else
            flash[:error] = 'Please contact HBX Admin to report this error'
          end
          redirect_to edit_profiles_registration_path(id: staff_params[:profile_id])
        end

        # For this person find an employer_staff_role that match this employer_profile_id and mark the role inactive
        def destroy
          @staff = BenefitSponsors::Organizations::OrganizationForms::StaffRoleForm.for_destroy(staff_params)
          authorize @staff
          @status, @result = @staff.destroy!
          if @status
            flash[:notice] = 'Staff role was deleted'
          else
            flash[:error] = @result
          end
          redirect_to edit_profiles_registration_path(id: staff_params[:profile_id])
        end

        private

        def staff_params
          params[:staff].present? ? params[:staff] : params[:staff] = {}
          params[:staff].merge!({profile_id: params["profile_id"] || params["id"], person_id: params["person_id"]})
          params[:staff].permit!
        end
      end
    end
  end
end



