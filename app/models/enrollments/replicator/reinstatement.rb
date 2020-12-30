module Enrollments
  module Replicator
    class Reinstatement

      attr_accessor :base_enrollment, :new_effective_date, :new_aptc, :year, :duplicate_hbx, :reinstate_enrollment

      def initialize(enrollment, effective_date, new_aptc=nil)
        @base_enrollment = enrollment
        @new_effective_date = effective_date
        @new_aptc = new_aptc
        @year = effective_date.year
        # TODO: dupliate_hbx was in the inherited code but was undefined. Need to know
        # what it is supposed to be
        @duplicate_hbx = enrollment.dup
      end

      def benefit_application
        base_enrollment.sponsored_benefit_package.benefit_application
      end

      def census_employee
        base_enrollment.benefit_group_assignment.census_employee
      end

      def reinstate_under_renewal_py?
        new_effective_date > benefit_application.end_on
      end

      def renewal_benefit_application
        benefit_application.benefit_sponsorship.benefit_applications.renewing.published_benefit_applications_by_date(new_effective_date).first
      end

      def renewal_benefit_group_assignment
        assignment = census_employee.renewal_benefit_group_assignment
        if assignment.blank?
          if census_employee.active_benefit_group_assignment.blank?
            census_employee.save
          end
          if renewal_benefit_application == census_employee.published_benefit_group_assignment.benefit_application
            assignment = census_employee.published_benefit_group_assignment
          end
        end
        assignment
      end

      def reinstatement_plan
        if reinstate_under_renewal_py?
          base_enrollment.product.renewal_product
        else
          base_enrollment.product
        end
      end

      def reinstatement_benefit_group_assignment
        if reinstate_under_renewal_py?
          renewal_benefit_group_assignment.id
        else
          base_enrollment.benefit_group_assignment_id
        end
      end

      def reinstatement_sponsored_benefit_package
        if reinstate_under_renewal_py?
          renewal_benefit_group_assignment.benefit_group
        else
          base_enrollment.sponsored_benefit_package
        end
      end

      def reinstatement_sponsored_benefit
        if base_enrollment.coverage_kind == 'health'
          reinstatement_sponsored_benefit_package.health_sponsored_benefit
        else
          reinstatement_sponsored_benefit_package.dental_sponsored_benefit
        end
      end

      def reinstate_rating_area
        if reinstate_under_renewal_py?
          renewal_benefit_group_assignment.benefit_application.recorded_rating_area_id
        else
          base_enrollment.rating_area_id
        end
      end

      def renewal_plan_offered_by_er?(renewal_plan)
        reinstatement_sponsored_benefit.products(new_effective_date).map(&:_id).include?(renewal_plan.id)
      end

      def can_be_reinstated?
        if reinstate_under_renewal_py?
          if !renewal_plan_offered_by_er?(reinstatement_plan)
            raise "Unable to reinstate enrollment: your Employer Sponsored Benefits no longer offerring the plan (#{reinstatement_plan.name})."
          end
        end
        true
      end

      def build
        reinstated_enrollment = HbxEnrollment.new
        @reinstate_enrollment = reinstated_enrollment
        assign_attributes_to_reinstate_enrollment(reinstated_enrollment, common_params)
        if base_enrollment.is_shop?
          assign_attributes_to_reinstate_enrollment(reinstated_enrollment, form_shop_params) if can_be_reinstated?
        elsif base_enrollment.is_ivl_by_kind?
          assign_attributes_to_reinstate_enrollment(reinstated_enrollment, form_ivl_params)
          if new_aptc.blank?
            reinstated_enrollment.elected_aptc_pct = base_enrollment.elected_aptc_pct
            reinstated_enrollment.applied_aptc_amount = base_enrollment.applied_aptc_amount
          end
        end
        reinstated_enrollment.hbx_enrollment_members = clone_hbx_enrollment_members
        if base_enrollment.may_terminate_coverage? && (reinstate_enrollment.effective_on > base_enrollment.effective_on)
          base_enrollment.terminate_coverage!
          base_enrollment.update_attributes!(terminated_on: reinstate_enrollment.effective_on - 1.day)
        else
          base_enrollment.cancel_coverage! if base_enrollment.may_cancel_coverage?
        end

        @reinstate_enrollment = reinstated_enrollment
        reinstated_enrollment
      end

      def assign_attributes_to_reinstate_enrollment(enrollment, options = {})
        enrollment.assign_attributes(options)
      end

      def form_shop_params
        {
          employee_role_id: base_enrollment.employee_role_id,
          benefit_group_assignment_id: reinstatement_benefit_group_assignment,
          sponsored_benefit_package_id: reinstatement_sponsored_benefit_package.id,
          sponsored_benefit_id: reinstatement_sponsored_benefit.id,
          benefit_sponsorship_id: base_enrollment.benefit_sponsorship_id,
          product_id: reinstatement_plan.id,
          rating_area_id: reinstate_rating_area,
          issuer_profile_id: reinstatement_plan.issuer_profile_id
        }
      end

      def form_ivl_params
        # TODO: Query is too long
        # TODO: undefined local variable or method `year' for #<Enrollments::Replicator::Reinstatement:0x00007fca4bcb2970>
        {
          product_id: base_enrollment.product_id,
          consumer_role_id: base_enrollment.consumer_role_id
        }
      end

      def common_params
        {
          family: base_enrollment.family,
          household: base_enrollment.family.active_household,
          effective_on: new_effective_date,
          coverage_kind: base_enrollment.coverage_kind,
          enrollment_kind: base_enrollment.enrollment_kind,
          kind: base_enrollment.kind,
          predecessor_enrollment_id: base_enrollment.id,
          hbx_enrollment_members: clone_hbx_enrollment_members
        }
      end

      def member_coverage_start_date(hbx_enrollment_member)
        if base_enrollment.is_shop? && reinstate_under_renewal_py?
          new_effective_date
        else
          hbx_enrollment_member.coverage_start_on || base_enrollment.effective_on || new_effective_date
        end
      end

      def clone_hbx_enrollment_members
        base_enrollment.hbx_enrollment_members.inject([]) do |members, hbx_enrollment_member|
          members << HbxEnrollmentMember.new({
                                                 applicant_id: hbx_enrollment_member.applicant_id,
                                                 eligibility_date: new_effective_date,
                                                 coverage_start_on: member_coverage_start_date(hbx_enrollment_member),
                                                 is_subscriber: hbx_enrollment_member.is_subscriber
                                             })
        end
      end
    end
  end
end
