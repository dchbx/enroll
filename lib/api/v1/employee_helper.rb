require_relative 'base_helper'

module Api
  module V1
    class EmployeeHelper < BaseHelper

      def benefit_group_assignments
        @benefit_group_assignments = @benefit_group.employees.map do |ee|
          ee.benefit_group_assignments.select do |bga|
            @benefit_group.ids.include?(bga.benefit_group_id) &&
                (PlanYear::RENEWING_PUBLISHED_STATE.include?(@benefit_group.plan_year.aasm_state) || bga.is_active)
          end
        end.flatten
      end

      #
      # A faster way of counting employees who are enrolled vs waived vs terminated
      # where enrolled + waived = counting towards SHOP minimum healthcare participation
      # We first do the query to find families with appropriate enrollments,
      # then check again inside the map/reduce to get only those enrollments.
      # This avoids undercounting, e.g. two family members working for the same employer.
      #
      def count_by_enrollment_status
        return [] if benefit_group_assignments.blank?

        enrolled_or_renewal = HbxEnrollment::ENROLLED_STATUSES + HbxEnrollment::RENEWAL_STATUSES
        waived = HbxEnrollment::WAIVED_STATUSES
        terminated = HbxEnrollment::TERMINATED_STATUSES

        id_list = @benefit_group_assignments.map(&:id)
        all_enrollments = FamilyHelper.hbx_enrollments id_list, enrolled_or_renewal + waived + terminated
        enrollment = EnrollmentHelper.new all_enrollments: all_enrollments
        enrollment.filter_active_employer_sponsored_health

        # return count of enrolled, count of waived, count of terminated
        # only including those originally asked for
        enrollment.benefit_group_assignment_ids enrolled_or_renewal, waived, terminated do |enrolled_ids, waived_ids, terminated_ids|
          [enrolled_ids, waived_ids, terminated_ids].map { |found_ids| (found_ids & id_list).count }
        end
      end

    end
  end
end