require_relative 'base_helper'

module Api
  module V1
    class SecurityHelper < BaseHelper

      def self.authorize_employer_list current_user, params
        if params[:id]
          broker_agency_profile = BrokerAgencyProfile.find params[:id]
          broker_agency_profile ? admin_or_staff(broker_agency_profile, current_user, params) : {status: 404}
        else
          broker_role current_user
        end
      end

      def self.can_view_employer_details? current_user, employer_profile
        can_view_employee_roster? current_user, employer_profile
      end

      def self.can_view_employee_roster? current_user, employer_profile
        employer_profile && (
        current_user.has_hbx_staff_role? ||
            current_user.person.broker_agency_staff_roles.map(&:broker_agency_profile_id).include?(employer_profile.active_broker_agency_account.broker_agency_profile_id) ||
            current_user.person.active_employer_staff_roles.map(&:employer_profile_id).include?(employer_profile.id) ||
            current_user.person.broker_role == employer_profile.active_broker_agency_account.writing_agent)
      end

      #
      # Private
      #
      private

      def self.broker_role current_user
        broker_role = current_user.person.broker_role
        broker_role ? {broker_agency_profile: broker_role.broker_agency_profile, broker_role: broker_role, status: 200} : {status: 404}
      end

      def self.admin_or_staff broker_agency_profile, current_user, params
        current_user.has_hbx_staff_role? || current_user.person.broker_agency_staff_roles.map(&:broker_agency_profile_id).include?(params[:id]) ? {broker_agency_profile: broker_agency_profile, status: 200} :
            {status: 404}
      end

    end
  end
end