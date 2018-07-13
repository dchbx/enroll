module Queries
  class NamedPolicyQueries

    def self.all_outstanding_shop
      qs = ::Queries::PolicyAggregationPipeline.new
      qs.filter_to_shop.filter_to_active.with_effective_date({"$gt" => Date.new(2015,1,31)}).eliminate_family_duplicates
      enroll_pol_ids = []
      qs.evaluate.each do |r|
        enroll_pol_ids << r['hbx_id']
      end
      enroll_pol_ids
    end

    def self.can_be_skipped?(hbx_id)
      enrollment = HbxEnrollment.by_hbx_id(hbx_id)[0]
      plan_year = enrollment.benefit_group.plan_year

      # Skip renewal enrollments that're purchased later than quiet period end date from shop monthly query.
      if plan_year.has_renewal_history?
        enrollment.submitted_at > plan_year.enrollment_quiet_period.end
      else
        plan_year.enrollment_quiet_period.cover?(enrollment.submitted_at)
      end
    end

    def self.shop_quiet_period_enrollments(effective_on, enrollment_statuses)
      feins = Organization.where(:"employer_profile.plan_years" => {:$elemMatch => {
        :start_on => effective_on, :aasm_state => 'enrolled'
        }}).pluck(:fein)

      qs = ::Queries::ShopMonthlyEnrollments.new(feins, effective_on)
      qs.enrollment_statuses = enrollment_statuses

      qs.query_families_with_quiet_period_enrollments
        .unwind_enrollments
        .query_quiet_period_enrollments
        .sort_enrollments
        .group_enrollment_events
        .project_enrollment_ids
      qs.evaluate.collect{|r| r['enrollment_hbx_id']}
    end
    
    def self.shop_monthly_enrollments(feins, effective_on)
      qs = ::Queries::ShopMonthlyEnrollments.new(feins, effective_on)

      qs.query_families_with_active_enrollments
        .unwind_enrollments
        .query_active_enrollments
        .sort_enrollments
        .group_enrollments
        .project_enrollment_ids
      qs.evaluate.reject{|r| Queries::NamedPolicyQueries.can_be_skipped?(r['enrollment_hbx_id'])}.collect{|r| r['enrollment_hbx_id']}
    end

    def self.shop_monthly_terminations(feins, effective_on)
      qs = ::Queries::ShopMonthlyEnrollments.new(feins, effective_on)
      qs.query_families
        .unwind_enrollments
        .query_enrollments
        .sort_enrollments
        .group_enrollments
        .project_enrollment_ids

      qs.evaluate.group_by{|r| r["_id"]["employee_role_id"]}.inject([]) do |termed_enrollments, (subscriber, records)|
        prev_enrollments = records.select{|r| r["_id"]["effective_on"] < effective_on}

        termed_enrollments += prev_enrollments.select do |prev_e|
          records.none? do |r|
            prev_e["_id"]["coverage_kind"] == r["_id"]["coverage_kind"] && r["_id"]["effective_on"] == effective_on 
          end
        end.collect{|record| record['enrollment_hbx_id']}
      end
    end
  end
end
