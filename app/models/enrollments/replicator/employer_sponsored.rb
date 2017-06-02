module Enrollments
  module Replicator

    class EmployerSponsored < Base

      def determine_replication_type
        current_plan_year = base_enrollment.benefit_group.plan_year
        employer = base_enrollment.employee_role.employer_profile
        new_plan_year = employer.plan_years.published_or_renewing_published.detect{|py| py.coverage_period_contains?(new_effective_date)}
        renewal_plan_year = employer.plan_years.renewing_published_state.first
        
        if current_plan_year == new_plan_year
          :reinstatement
        elsif renewal_plan_year == new_plan_year
          :renewal
        else
          :unknown
        end
      end
    end
  end
end