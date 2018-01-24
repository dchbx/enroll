module Api
  module V1
    module Mobile
      class SecurityUtil < BaseUtil

        def authorize_employer_list
          return broker_role unless @params[:id]
          @broker_agency_profile = BrokerAgencyProfile.find @params[:id]
          @broker_agency_profile ? admin_or_staff : {status: 404}
        end

        def can_view_employer_details?
          can_view_employee_roster?
        end

        def can_view_employee_roster?
          @employer_profile && (
          @user.has_hbx_staff_role? ||
              @user.person.broker_agency_staff_roles.map(&:broker_agency_profile_id).include?(@employer_profile.try(:active_broker_agency_account).try(:broker_agency_profile_id)) ||
              @user.person.active_employer_staff_roles.map(&:employer_profile_id).include?(@employer_profile.id) ||
              @user.person.broker_role == @employer_profile.active_broker_agency_account.writing_agent)
        end

        #
        # Private
        #
        private

        def broker_role
          broker_role = @user.person.broker_role
          broker_role ? {broker_agency_profile: broker_role.broker_agency_profile, broker_role: broker_role, status: 200} : {status: 404}
        end

        def admin_or_staff
          @user.has_hbx_staff_role? || @user.person.broker_agency_staff_roles.map(&:broker_agency_profile_id).include?(@params[:id]) ? {broker_agency_profile: @broker_agency_profile, status: 200} :
              {status: 404}
        end

      end
    end
  end
end