require_relative 'base_helper'

module Api
  module V1
    class EnrollmentHelper < BaseHelper

      def filter_active_employer_sponsored_health
        @active_health_enrollments = @all_enrollments.select do |enrollment|
          enrollment.kind == 'employer_sponsored' &&
              enrollment.coverage_kind == 'health' &&
              enrollment.is_active
        end
      end

      def benefit_group_assignment_ids enrolled, waived, terminated
        yield bg_assignment_ids(enrolled), bg_assignment_ids(waived), bg_assignment_ids(terminated)
      end

      #
      # Private
      #
      private

      def bg_assignment_ids statuses
        @active_health_enrollments.select do |enrollment|
          statuses.include? (enrollment.aasm_state)
        end.map(&:benefit_group_assignment_id)
      end

    end
  end
end