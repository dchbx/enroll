module Notifier
  module Builders::Enrollment

    def enrollment
      return @enrollment if defined? @enrollment
      if payload['event_object_kind'].constantize == HbxEnrollment
        @enrollment = HbxEnrollment.find(payload['event_object_id'])
      elsif event_matched?
        @enrollment = health_enrollment
      end
    end

    def parent_enrollment
      return if enrollment.blank?

      enrollment.parent_enrollment
    end

    def enrollment_waiver_plan_name
      return if parent_enrollment.blank?

      merge_model.enrollment.waiver_plan_name = parent_enrollment.plan.name
    end

    def enrollment_waiver_enrolled_count
      return if parent_enrollment.blank?

      merge_model.enrollment.waiver_enrolled_count = parent_enrollment.humanized_dependent_summary
    end

    def enrollment_waiver_coverage_end_on
      return if parent_enrollment.blank?

      merge_model.enrollment.waiver_coverage_end_on = parent_enrollment.terminated_on
    end

    def enrollment_waiver_effective_on
      effective_date =
        if parent_enrollment.present?
          parent_enrollment.terminated_on.nil? ? parent_enrollment.effective_on : parent_enrollment.terminated_on + 1.day
        else
          enrollment.effective_on
        end

      merge_model.enrollment.waiver_effective_on = format_date(effective_date)
    end

    def dental_enrollment
      if event_matched?
        enrollments.by_coverage_kind("dental").max_by(&:created_at)
      end
    end

    def event_matched?
      ["employee_notice_for_employee_terminated_from_roster", "initial_employee_plan_selection_confirmation", "renewal_employee_enrollment_confirmation"].include?(event_name)
    end

    def enrollments
      employee_role.person.primary_family.active_household.hbx_enrollments.shop_market.enrolled_and_renewing
    end

    def health_enrollment
      enrollments.by_coverage_kind("health").max_by(&:created_at)
    end

    def latest_terminated_health_enrollment
      enrollment = employee_role.person.primary_family.active_household.hbx_enrollments.shop_market.by_coverage_kind("health").where(:aasm_state.in => ['coverage_termination_pending', 'coverage_terminated']).detect do |hbx|
        census_employee_record.employment_terminated_on < hbx.terminated_on
      end
      enrollment
    end

    def enrollment_coverage_start_on
      return if enrollment.blank?
      merge_model.enrollment.coverage_start_on = format_date(enrollment.effective_on)
    end

    def enrollment_coverage_end_on
      return if enrollment.blank?
      merge_model.enrollment.coverage_end_on = format_date(enrollment.terminated_on)
    end

    def enrollment_coverage_end_on_minus_60_days
      return if census_employee_record.blank?
      merge_model.enrollment.coverage_end_on_minus_60_days = format_date(census_employee_record.coverage_terminated_on - 60.days)
    end

    def enrollment_coverage_end_on_plus_60_days
      return if census_employee_record.blank?
      merge_model.enrollment.coverage_end_on_plus_60_days = format_date(census_employee_record.coverage_terminated_on + 60.days)
    end

    def enrollment_plan_name
      return if enrollment.blank?
      merge_model.enrollment.plan_name = enrollment.product.name
    end

    def enrollment_enrolled_count
      return if enrollment.blank?
      merge_model.enrollment.enrolled_count = enrollment.humanized_dependent_summary
    end

    def enrollment_coverage_kind
      return if enrollment.blank?
      merge_model.enrollment.coverage_kind = enrollment.coverage_kind
    end

    def enrollment_enrollment_kind
      return if enrollment.blank?

      merge_model.enrollment.enrollment_kind = enrollment.enrollment_kind
    end

    def enrollment_employee_responsible_amount
      return if enrollment.blank?
      merge_model.enrollment.employee_responsible_amount = number_to_currency(enrollment.total_employee_cost, precision: 2)
    end

    def enrollment_employer_responsible_amount
      return if enrollment.blank?
      merge_model.enrollment.employer_responsible_amount = number_to_currency(enrollment.total_employer_contribution, precision: 2)
    end

    def enrollment_employee_first_name
      return if enrollment.blank?
      merge_model.enrollment.employee_first_name = enrollment.census_employee.first_name
    end

    def enrollment_employee_last_name
      return if enrollment.blank?
      merge_model.enrollment.employee_last_name = enrollment.census_employee.last_name
    end

    def dental_enrollment_coverage_start_on
      return if dental_enrollment.blank?
      merge_model.dental_enrollment.coverage_start_on = format_date(dental_enrollment.effective_on)
    end

    def dental_enrollment_coverage_end_on
      return if dental_enrollment.blank?
      merge_model.dental_enrollment.coverage_end_on = format_date(dental_enrollment.terminated_on)
    end

    def dental_enrollment_coverage_end_on_minus_60_days
      return if census_employee_record.blank?
      merge_model.dental_enrollment.coverage_end_on_minus_60_days = format_date(census_employee_record.coverage_terminated_on - 60.days)
    end

    def dental_enrollment_coverage_end_on_plus_60_days
      return if census_employee_record.blank?
      merge_model.dental_enrollment.coverage_end_on_plus_60_days = format_date(census_employee_record.coverage_terminated_on + 60.days)
    end

    def dental_enrollment_plan_name
      return if dental_enrollment.blank?
      merge_model.dental_enrollment.plan_name = dental_enrollment.product.name
    end

    def dental_enrollment_enrolled_count
      return if dental_enrollment.blank?
      merge_model.dental_enrollment.enrolled_count = dental_enrollment.humanized_dependent_summary
    end

    def dental_enrollment_coverage_kind
      return if dental_enrollment.blank?
      merge_model.dental_enrollment.coverage_kind = dental_enrollment.coverage_kind
    end

    def dental_enrollment_employee_responsible_amount
      return if dental_enrollment.blank?
      merge_model.dental_enrollment.employee_responsible_amount = number_to_currency(dental_enrollment.total_employee_cost, precision: 2)
    end

    def dental_enrollment_employer_responsible_amount
      return if dental_enrollment.blank?
      merge_model.dental_enrollment.employer_responsible_amount = number_to_currency(dental_enrollment.total_employer_contribution, precision: 2)
    end

    def dental_enrollment_employee_first_name
      return if dental_enrollment.blank?
      merge_model.dental_enrollment.employee_first_name = dental_enrollment.census_employee.first_name
    end

    def dental_enrollment_employee_last_name
      return if dental_enrollment.blank?
      merge_model.dental_enrollment.employee_last_name = dental_enrollment.census_employee.last_name
    end
  end
end
