# frozen_string_literal: true

module ManageAccount
  module Portals
  # Has fields related to employer staff protal page under manage account
    class EmployerStaff

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

      def self.gender
        'staff_member[coverage_record][gender]'
      end

      def self.hired_on
        'staff_member[coverage_record][hired_on]'
      end

      def self.is_applying_coverage
        'staff_member[coverage_record][is_applying_coverage]'
      end

      def self.ssn
        'staff_member[coverage_record][ssn]'
      end

      def self.address_1
        'staff_member[coverage_record][address][address_1]'
      end

      def self.address_2
        'staff_member[coverage_record][address][address_2]'
      end

      def self.city
        'staff_member[coverage_record][address][city]'
      end

      def self.state
        'staff_member[coverage_record][address][state]'
      end

      def self.zip
        'staff_member[coverage_record][address][zip]'
      end

      def self.coverage_record_email_kind
        'staff_member[coverage_record][email][kind]'
      end

      def self.coverage_record_email_address
        'staff_member[coverage_record][email][address]'
      end

      def self.employer_search
        'example-search-input'
      end

      def self.success_message
        'Successfully added employer staff role'
      end
    end
  end
end
