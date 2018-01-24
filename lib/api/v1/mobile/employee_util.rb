module Api
  module V1
    module Mobile
      class EmployeeUtil < BaseUtil
        include CacheUtil
        ROSTER_ENROLLMENT_PLAN_FIELDS_TO_RENDER = [:plan_type, :deductible, :family_deductible, :provider_directory_url, :rx_formulary_url]

        def initialize args={}
          super args
        end

        def employees_sorted_by
          census_employees = case @status
                               when 'terminated'
                                 @employer_profile.census_employees.terminated
                               when 'all'
                                 @employer_profile.census_employees
                               else
                                 @employer_profile.census_employees.active
                             end.sorted
          @employee_name ? census_employees.employee_name(@employee_name) : census_employees
        end

        def roster_employees
          cache = plan_and_benefit_group @employees, @employer_profile
          @employees.compact.map { |ee|
            if cache
              benefit_group_assignments = cache[:employees_benefits].detect { |b| b.keys.include? ee.id.to_s }.try(:[], :benefit_group_assignments) || []
              roster_employee ee, benefit_group_assignments, cache[:grouped_bga_enrollments]
            else
              roster_employee ee, ee.benefit_group_assignments
            end
          }
        end

        #
        # A faster way of counting employees who are enrolled vs waived vs terminated
        # where enrolled + waived = counting towards SHOP minimum healthcare participation
        # We first do the query to find families with appropriate enrollments,
        # then check again inside the map/reduce to get only those enrollments.
        # This avoids undercounting, e.g. two family members working for the same employer.
        #
        def count_by_enrollment_status
          return [0, 0, 0] if benefit_group_assignments.blank?

          enrolled_or_renewal = HbxEnrollment::ENROLLED_STATUSES + HbxEnrollment::RENEWAL_STATUSES
          waived = HbxEnrollment::WAIVED_STATUSES
          terminated = HbxEnrollment::TERMINATED_STATUSES

          id_list = @benefit_group_assignments.map(&:id)
          all_enrollments = FamilyUtil.new(benefit_group_assignment_ids: id_list, aasm_states: enrolled_or_renewal + waived + terminated).hbx_enrollments
          enrollment = EnrollmentUtil.new all_enrollments: all_enrollments

          # return count of enrolled, count of waived, count of terminated
          # only including those originally asked for
          enrollment.benefit_group_assignment_ids enrolled_or_renewal, waived, terminated do |enrolled_ids, waived_ids, terminated_ids|
            [enrolled_ids, waived_ids, terminated_ids].map { |found_ids| (found_ids & id_list).count }
          end
        end

        #
        # Private
        #
        private

        def benefit_group_assignments
          @benefit_group_assignments ||= @benefit_group.employees.map do |ee|
            ee.benefit_group_assignments.select do |bga|
              @benefit_group.ids.include?(bga.benefit_group_id) &&
                  (::PlanYear::RENEWING_PUBLISHED_STATE.include?(@benefit_group.plan_year.aasm_state) || bga.is_active)
            end
          end.flatten
        end

        def roster_employee employee, benefit_group_assignments, grouped_bga_enrollments=nil
          result = employee_hash employee
          enrollment_util = EnrollmentUtil.new(
              assignments: current_or_upcoming_assignments(benefit_group_assignments))
          enrollment_util.grouped_bga_enrollments = grouped_bga_enrollments if grouped_bga_enrollments
          result[:enrollments] = enrollment_util.employee_enrollments
          add_dependents employee, result
          result
        end

        def add_dependents employee, result
          result[:dependents] = dependents_of(employee).map do |d|
            basic_individual(d).merge(relationship: relationship_with(d))
          end
        end

        def current_or_upcoming_assignments benefit_group_assignments
          benefit_group_assignments.select { |a| PlanYearUtil.new(plan_year: a.plan_year).is_current_or_upcoming? }
        end

        def employee_hash employee
          result = basic_individual employee
          result[:id] = employee.id
          result[:hired_on] = employee.hired_on
          result[:is_business_owner] = employee.is_business_owner
          result
        end

        def basic_individual employee
          ssn = employee.try(:ssn)
          ssn_masked = "***-**-#{ ssn.chars.last(4).join }" if ssn

          {first_name: employee.try(:first_name),
           middle_name: employee.try(:middle_name),
           last_name: employee.try(:last_name),
           name_suffix: employee.try(:name_sfx),
           date_of_birth: employee.try(:dob),
           ssn_masked: ssn_masked,
           gender: employee.try(:gender)
          }
        end

        def dependents_of employee
          all_family_dependents = employee.try(:employee_role).try(:person).try(:primary_family).try(:active_family_members) || []
          family_dependents = all_family_dependents.reject { |d| relationship_with(d) == 'self' }
          census_dependents = employee.census_dependents || []
          (family_dependents + census_dependents).uniq { |p| p.ssn }
        end


        def relationship_with dependent
          dependent.try(:relationship) || dependent.try(:employee_relationship)
        end

      end
    end
  end
end