require_relative 'base_helper'

module Api
  module V1
    class SecurityHelper < BaseHelper

      def self.authorize_employer_list current_user, params
        if params[:id]
          broker_agency_profile = BrokerAgencyProfile.find params[:id]
          broker_agency_profile ? admin_or_staff(broker_agency_profile, current_user, params) : {status: 404}
        else
          current_user.has_hbx_staff_role? ? {status: 406} : broker_role(current_user)
        end
      end

      def self.can_view_employer_details? current_user
        true #TODO(krish)
      end

      def self.can_view_employee_roster? current_user
        true #TODO(krish)
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