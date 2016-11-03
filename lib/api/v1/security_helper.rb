require_relative 'base_helper'

module Api
  module V1
    class SecurityHelper < BaseHelper

      def self.can_view_employer_list? current_user, params
        true # TODO(krish)
      end

      def self.can_view_employer_details? current_user
        true #TODO(krish)
      end

      def self.can_view_employee_roster? current_user
        true #TODO(krish)
      end

    end
  end
end