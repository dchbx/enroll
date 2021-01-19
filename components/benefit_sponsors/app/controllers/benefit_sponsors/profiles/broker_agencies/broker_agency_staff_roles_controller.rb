module BenefitSponsors
  module Profiles
    module BrokerAgencies
      class BrokerAgencyStaffRolesController < ::BenefitSponsors::ApplicationController

        layout 'bootstrap_4_two_column', :only => :new_staff_member

        def new
          @staff = BenefitSponsors::Organizations::OrganizationForms::StaffRoleForm.for_new
          set_ie_flash_by_announcement

          respond_to do |format|
            format.html { render 'new', layout: false} if params[:profile_type]
            format.js  { render 'new'}
          end
        end

        def create
          @staff = BenefitSponsors::Organizations::OrganizationForms::StaffRoleForm.for_create(broker_staff_params)
          begin
            @status,@result = @staff.save
            unless @staff.is_broker_registration_page
              flash[:notice] = "Role added successfully" if @status
              flash[:error] = "Role was not added because " + @result unless @status
            end
          rescue Exception => e
            flash[:error] = "Role was not added because " + e.message
          end
          respond_to do |format|
            format.html  { redirect_to profiles_broker_agencies_broker_agency_profile_path(id: params[:profile_id])}
            format.js
          end
        end

        def approve
          @staff = BenefitSponsors::Organizations::OrganizationForms::StaffRoleForm.for_approve(broker_staff_params)
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
          redirect_to profiles_broker_agencies_broker_agency_profile_path(id: params[:profile_id])
        end

        def destroy
          @staff = BenefitSponsors::Organizations::OrganizationForms::StaffRoleForm.for_destroy(broker_staff_params)
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
          redirect_to profiles_broker_agencies_broker_agency_profile_path(id: params[:profile_id])
        end

        def search_broker_agency
          @staff = BenefitSponsors::Organizations::OrganizationForms::StaffRoleForm.for_broker_agency_search(broker_staff_params)
          @broker_agency_profiles = @staff.broker_agency_search
        end

        def new_staff_member
          authorize User, :add_roles?
          @staff_member = BenefitSponsors::Operations::BrokerAgencies::Forms::NewBrokerAgencyStaff.new.call(params).value!
        end

        def create_staff_member
          authorize User, :add_roles?
          staff_params = params.permit[:staff_member].to_h
          result = BenefitSponsors::Operations::BrokerAgencies::AddBrokerAgencyStaff.new.call(staff_member_params.merge(dob: parse_date(staff_member_params['dob'])))
          if result.success?
            redirect_to main_app.show_roles_person_path(id: staff_params[:person_id])
            flash[:notice] = result.value![:message]
          else
            redirect_to new_staff_member_profiles_broker_agencies_broker_agency_staff_roles_path(id: staff_params[:person_id])
            flash[:error] = result.failure[:message]
          end
        end

        private

        def broker_staff_params
          params[:staff].presence || params[:staff] = {}
          params[:staff].merge!({profile_id: params["staff"]["profile_id"] || params["profile_id"] || params["id"], person_id: params["person_id"], profile_type: params[:profile_type] || "broker_agency_staff",
                                  filter_criteria: params.permit(:q), is_broker_registration_page: params[:broker_registration_page] || params["staff"]["is_broker_registration_page"]})
          params[:staff].permit!
        end

        def staff_member_params
          params.require(:staff_member).permit(
            :first_name,
            :last_name,
            :dob,
            :email,
            :person_id,
            :profile_id
          ).to_h
        end

        def parse_date(date)
          Date.strptime(date, "%m/%d/%Y") if date
        end
      end
    end
  end
end
