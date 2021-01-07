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
          authorize User, :add_roles?
          @staff_member = ::Operations::Employers::NewEmployerStaff.new.call(params).value!
        end

        def create_staff_member
          authorize User, :add_roles?
          result = ::Operations::Employers::AddEmployerStaff.new.call(staff_member_params.merge(dob: parse_date(staff_member_params['dob'])))
          # add redirects
          if result.success?
            redirect_to main_app.show_roles_person_path(id: staff_member_params[:person_id])
            flash[:notice] = result.value![:message]
          else
            redirect_to new_staff_member_profiles_employers_employer_staff_roles_path(id: staff_member_params[:person_id])
            flash[:error] = result.failure[:message]
          end
        end

        def employer_search
          @search_value = params["q"]

          return [] if @search_value.blank?

          @employer_profile_organizations = BenefitSponsors::Organizations::Organization.employer_profiles.datatable_search(@search_value)
        end

        def index
          @profile = BenefitSponsors::Organizations::Profile.find(params[:profile_id])
          authorize @profile, :list_staff_roles?
          @element_to_replace_id = params[:employer_actions_id].to_s
          @staff_people = Person.staff_for_employer(@profile)
        end

        private

        def staff_params
          params[:staff] ||= {}
          params[:staff].merge!({profile_id: params["profile_id"] || params["id"], person_id: params["person_id"]})
          params[:staff].permit!
        end

        def staff_member_params
          params.require(:staff_member).permit(
            :first_name,
            :last_name,
            :dob,
            :email,
            :person_id,
            :profile_id,
            :coverage_record => [
              :is_applying_coverage,
              :ssn,
              :gender,
              :hired_on,
              {:address => [:kind, :address_1, :address_2, :city, :state, :zip],
               :email => [:kind, :address]}
            ]
          ).to_h
        end

        def parse_date(date)
          Date.strptime(date, "%m/%d/%Y") if date
        end
      end
    end
  end
end



