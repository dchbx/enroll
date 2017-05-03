module Api
  module V1
    module Mobile
      module CacheUtil

        def plan_and_benefit_group employees, employer_profile
          begin
            employees_benefits = employees.map do |e|
              {"#{e.id}" => e, benefit_group_assignments: e.benefit_group_assignments.select do |bga|
                bga.is_active? || TimeKeeper.date_of_record < bga.start_on
              end }
            end.flatten
            benefit_group_assignment_ids = employees_benefits.map { |x| x[:benefit_group_assignments] }.flatten.map(&:id)
            enrollments_for_benefit_groups = hbx_enrollments benefit_group_assignment_ids
            grouped_bga_enrollments = enrollments_for_benefit_groups.group_by { |x| x.benefit_group_assignment_id.to_s }

            plan_ids = enrollments_for_benefit_groups.map { |x| x.plan_id }.flatten
            indexed_plans = Plan.where(:'id'.in => plan_ids).index_by(&:id)
            benefit_groups = employer_profile.plan_years.map { |p| p.benefit_groups }.flatten.compact.index_by(&:id)
            enrollments_for_benefit_groups.map { |e|
              e.plan = indexed_plans[e.plan_id] if e.plan_id
              e.benefit_group = benefit_groups[e.benefit_group_id] if e.benefit_group_id
            }
            result = {employees_benefits: employees_benefits, grouped_bga_enrollments: grouped_bga_enrollments}
          rescue Exception => e
            Rails.logger.error "Exception caught in plan_and_benefit_group: #{e.message}"
            e.backtrace.each { |line| Rails.logger.error line }
          end
          result
        end

        #
        # Private
        #
        private

        def hbx_enrollments benefit_group_assignment_ids
          families = Family.where(:'households.hbx_enrollments'.elem_match => {
              :'benefit_group_assignment_id'.in => benefit_group_assignment_ids
          })
          families.map { |f| f.households.map { |h| h.hbx_enrollments.show_enrollments_sans_canceled } }.flatten.compact
        end

      end
    end
  end
end