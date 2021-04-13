# frozen_string_literal: true

module ManageAccount
  module Portals
    # Has fields related to employer staff protal page under manage account
    class GeneralAgencyStaff

      def self.first_name
        'staff_member[first_name]'
      end

      def self.last_name
        'staff_member[last_name]'
      end

      def self.dob
        'staff_member[dob]'
      end

      def self.email
        'staff_member[email]'
      end

      def self.general_agency_search
        'general-agency-search-input'
      end

      def self.success_message
        'Successfully added general agency staff role'
      end
    end
  end
end
