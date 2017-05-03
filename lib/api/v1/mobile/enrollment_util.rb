module Api
  module V1
    module Mobile

      module EnrollmentConstants
        WAIVED = 'Waived'
        TERMINATED = 'Terminated'
        ENROLLED = 'Enrolled'
      end

      class EnrollmentUtil < BaseUtil
        attr_accessor :grouped_bga_enrollments

        def benefit_group_assignment_ids enrolled, waived, terminated
          yield bg_assignment_ids(enrolled), bg_assignment_ids(waived), bg_assignment_ids(terminated)
        end

        def employee_enrollments
          @assignments.map do |assignment|
            hbx_enrollments = @grouped_bga_enrollments[assignment.id.to_s] unless !@grouped_bga_enrollments || @grouped_bga_enrollments.empty?
            enrollment_year = {start_on: assignment.plan_year.start_on}
            %w{health dental}.each do |coverage_kind|
              enrollments = hbx_enrollments ? hbx_enrollments : assignment.hbx_enrollments
              enrollment, rendered_enrollment = initialize_enrollment enrollments, coverage_kind

              EmployeeUtil::ROSTER_ENROLLMENT_PLAN_FIELDS_TO_RENDER.each do |field|
                value = enrollment.plan.try(field)
                rendered_enrollment[field] = value if value
              end if enrollment && enrollment.plan

              enrollment_termination! enrollment, rendered_enrollment
              enrollment_waived! enrollment, rendered_enrollment
              enrollment_year[coverage_kind] = rendered_enrollment
            end
            enrollment_year
          end
        end

        #
        # Private
        #
        private

        def bg_assignment_ids statuses
          active_employer_sponsored_health_enrollments.select do |enrollment|
            statuses.include? (enrollment.aasm_state)
          end.map(&:benefit_group_assignment_id)
        end

        def active_employer_sponsored_health_enrollments
          @active_employer_sponsored_health_enrollments ||= @all_enrollments.select do |enrollment|
            enrollment.kind == 'employer_sponsored' &&
                enrollment.coverage_kind == 'health' &&
                enrollment.is_active
          end.compact.sort do |e1, e2|
            e2.submitted_at.to_i <=> e1.submitted_at.to_i # most recently submitted first
          end.uniq do |e|
            e.benefit_group_assignment_id # only the most recent per employee
          end
        end

        def enrollment_termination! enrollment, rendered_enrollment
          return unless rendered_enrollment[:status] == EnrollmentConstants::TERMINATED
          rendered_enrollment[:terminated_on] = format_date enrollment.terminated_on
          rendered_enrollment[:terminate_reason] = enrollment.terminate_reason
        end

        def enrollment_waived! enrollment, rendered_enrollment
          return unless rendered_enrollment[:status] == EnrollmentConstants::WAIVED
          rendered_enrollment[:waived_on] = format_date(enrollment.submitted_at || enrollment.created_at)
          rendered_enrollment[:waiver_reason] = enrollment.waiver_reason
        end

        def initialize_enrollment hbx_enrollments, coverage_kind
          enrollment = hbx_enrollments.flatten.detect { |e| e.coverage_kind == coverage_kind } unless !hbx_enrollments || hbx_enrollments.empty?
          rendered_enrollment = if enrollment
                                  {hbx_enrollment_id: enrollment.id,
                                   status: status_label_for(enrollment.aasm_state),
                                   employer_contribution: enrollment.total_employer_contribution,
                                   employee_cost: enrollment.total_employee_cost,
                                   total_premium: enrollment.total_premium,
                                   plan_name: enrollment.plan.try(:name),
                                   plan_type: enrollment.plan.try(:plan_type),
                                   metal_level: enrollment.plan.try(coverage_kind == :health ? :metal_level : :dental_level),
                                   benefit_group_name: enrollment.try(:benefit_group).try(:title)
                                  }
                                else
                                  {status: 'Not Enrolled'}
                                end
          return enrollment, rendered_enrollment
        end


        def status_label_for enrollment_status
          {
              EnrollmentConstants::WAIVED => HbxEnrollment::WAIVED_STATUSES,
              EnrollmentConstants::ENROLLED => HbxEnrollment::ENROLLED_AND_RENEWAL_STATUSES,
              EnrollmentConstants::TERMINATED => HbxEnrollment::TERMINATED_STATUSES
          }.inject(nil) do |result, (label, enrollment_statuses)|
            enrollment_statuses.include?(enrollment_status.to_s) ? label : result
          end
        end

      end
    end
  end
end