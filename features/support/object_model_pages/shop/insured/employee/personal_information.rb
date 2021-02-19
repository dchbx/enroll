# frozen_string_literal: true

module Insured
  module Employee
  # Has fields related to person while signing up as an employee
    class PersonalInformation

      def self.first_name
        'person[first_name]'
      end

      def self.middle_name
        'person[middle_name]'
      end

      def self.last_name
        'person[last_name]'
      end

      def self.dob
        'jq_datepicker_ignore_person[dob]'
      end

      def self.ssn
        'person[ssn]'
      end

      def self.no_ssn
        'person[no_ssn]'
      end

      def self.gender
        'person[gender]'
      end
    end
  end
end
