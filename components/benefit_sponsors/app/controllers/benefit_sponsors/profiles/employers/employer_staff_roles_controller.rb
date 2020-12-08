module BenefitSponsors
  module Profiles
    module Employers
      class EmployerStaffRolesController < ::BenefitSponsors::ApplicationController

        include Pundit

        layout 'bootstrap_4_two_column', :only => :new_staff_member

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
            @status , @result = @staff.save
            unless @status
              flash[:error] = ('Role was not added because '  + @result)
            else
              flash[:notice] = "Role added sucessfully"
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
          @status , @result = @staff.approve
          unless @status
            flash[:error] = 'Please contact HBX Admin to report this error'
          else
            flash[:notice] = 'Role is approved'
          end
          redirect_to edit_profiles_registration_path(id: staff_params[:profile_id])
        end

        # For this person find an employer_staff_role that match this employer_profile_id and mark the role inactive
        def destroy
          @staff = BenefitSponsors::Organizations::OrganizationForms::StaffRoleForm.for_destroy(staff_params)
          authorize @staff
          @status , @result = @staff.destroy!
          unless @status
            flash[:error] = @result
          else
            flash[:notice] = 'Staff role was deleted'
          end
          redirect_to edit_profiles_registration_path(id: staff_params[:profile_id])
        end

        def new_staff_member
          # Add pundit policy
          authorize User, :add_roles?
          @person = Person.find(params["id"])
          @staff_member = ::Operations::People::Roles::NewStaff.new.call(params).value!
        end

        def create_staff_member
          # Add pundit policy
          authorize User, :add_roles?
          result = ::Operations::People::Roles::PersistStaff.new.call(params)
          # add redirects
          if result.success?
          else
          end
        end

        def employer_search
          @search_value = params.permit!.to_h["q"]

          return [] if @search_value.blank?

          @employer_profiles = BenefitSponsors::Organizations::Organization.employer_profiles.datatable_search(@search_value)
        end

        private

        def staff_params
          params[:staff].present? ? params[:staff] :  params[:staff] = {}
          params[:staff].merge!({profile_id: params["profile_id"] || params["id"], person_id: params["person_id"]})
          params[:staff].permit!
        end
      end
    end
  end
end



