module Enrollments
  module Replicator
    class Reinstatement

      attr_accessor :base_enrollment, :new_effective_date

      def initialize(enrollment, effective_date)
        @base_enrollment = enrollment
        @new_effective_date = effective_date
      end

      def build
        family = base_enrollment.family
        reinstated_enrollment = family.active_household.hbx_enrollments.new

        reinstated_enrollment.effective_on = new_effective_date
        reinstated_enrollment.coverage_kind = base_enrollment.coverage_kind
        reinstated_enrollment.enrollment_kind = base_enrollment.enrollment_kind
        reinstated_enrollment.kind = base_enrollment.kind
        reinstated_enrollment.plan_id = base_enrollment.plan_id

        if base_enrollment.is_shop?
          reinstated_enrollment.employee_role_id = base_enrollment.employee_role_id
          reinstated_enrollment.benefit_group_assignment_id = base_enrollment.benefit_group_assignment_id
          reinstated_enrollment.benefit_group_id = base_enrollment.benefit_group_id
        else
          reinstated_enrollment.consumer_role_id = base_enrollment.consumer_role_id
          reinstated_enrollment.elected_aptc_pct = base_enrollment.elected_aptc_pct
          reinstated_enrollment.applied_aptc_amount = base_enrollment.applied_aptc_amount
        end

        reinstated_enrollment.hbx_enrollment_members = clone_hbx_enrollment_members
        reinstated_enrollment
      end

      def clone_hbx_enrollment_members
        base_enrollment.hbx_enrollment_members.inject([]) do |members, hbx_enrollment_member|
          members << HbxEnrollmentMember.new({
            applicant_id: hbx_enrollment_member.applicant_id,
            eligibility_date: new_effective_date,
            coverage_start_on: hbx_enrollment_member.coverage_start_on || base_enrollment.effective_on || new_effective_date,
            is_subscriber: hbx_enrollment_member.is_subscriber
          })
        end
      end
    end
  end
end