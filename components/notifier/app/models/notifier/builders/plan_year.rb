module Notifier
  module Builders::PlanYear

    def plan_year_current_py_start_date
      if current_plan_year.present?
        merge_model.plan_year.current_py_start_date = format_date(current_plan_year.start_on)
      end
    end

    def plan_year_current_py_end_date
      if current_plan_year.present?
        merge_model.plan_year.current_py_end_date = format_date(current_plan_year.end_on)
      end
    end

    def plan_year_renewal_py_start_date
      if renewal_plan_year.present?
        merge_model.plan_year.renewal_py_start_date = format_date(renewal_plan_year.start_on) 
      end
    end

    def plan_year_renewal_py_end_date
      if renewal_plan_year.present?
        merge_model.plan_year.renewal_py_end_date = format_date(renewal_plan_year.end_on)
      end
    end

    def plan_year_current_py_oe_start_date
      if current_plan_year.present?
        merge_model.plan_year.current_py_oe_start_date = format_date(current_plan_year.open_enrollment_start_on)
      end
    end

    def plan_year_current_py_oe_end_date
      if current_plan_year.present?
        merge_model.plan_year.current_py_oe_end_date = format_date(current_plan_year.open_enrollment_end_on)
      end
    end

    def plan_year_renewal_py_oe_start_date
      if renewal_plan_year.present?
        merge_model.plan_year.renewal_py_oe_start_date = format_date(renewal_plan_year.open_enrollment_start_on)
      end
    end

    def plan_year_renewal_py_oe_end_date
      if renewal_plan_year.present?
        merge_model.plan_year.renewal_py_oe_end_date = format_date(renewal_plan_year.open_enrollment_end_on)
      end
    end

    def plan_year_initial_py_publish_advertise_deadline
      if current_plan_year.present?
        prev_month = current_plan_year.start_on.prev_month
        merge_model.plan_year.initial_py_publish_advertise_deadline = format_date(Date.new(prev_month.year, prev_month.month, Settings.aca.shop_market.initial_application.advertised_deadline_of_month))
      end
    end

    def plan_year_initial_py_publish_due_date
      if current_plan_year.present?
        prev_month = current_plan_year.start_on.prev_month
        merge_model.plan_year.initial_py_publish_due_date = format_date(Date.new(prev_month.year, prev_month.month, Settings.aca.shop_market.initial_application.publish_due_day_of_month))
      end
    end

    def plan_year_renewal_py_submit_soft_due_date
      if renewal_plan_year.present?
        prev_month = renewal_plan_year.start_on.prev_month
        merge_model.plan_year.renewal_py_submit_soft_due_date = format_date(Date.new(prev_month.year, prev_month.month, Settings.aca.shop_market.renewal_application.application_submission_soft_deadline))
      end
    end

    def plan_year_renewal_py_submit_due_date
      if renewal_plan_year.present?
        prev_month = renewal_plan_year.start_on.prev_month
        merge_model.plan_year.renewal_py_submit_due_date = format_date(Date.new(prev_month.year, prev_month.month, Settings.aca.shop_market.renewal_application.publish_due_day_of_month))
      end
    end

    def plan_year_binder_payment_due_date
      if current_plan_year.present?
        merge_model.plan_year.binder_payment_due_date = format_date(PlanYear.map_binder_payment_due_date_by_start_on(current_plan_year.start_on))
      end
    end

    def plan_year_current_py_start_on
      if current_plan_year.present?
        merge_model.plan_year.current_py_start_on = current_plan_year.start_on
      end
    end

    def plan_year_current_py_end_on
      if current_plan_year.present?
        merge_model.plan_year.current_py_end_on = current_plan_year.end_on
      end
    end

    def plan_year_renewal_py_start_on
      if renewal_plan_year.present?
        merge_model.plan_year.renewal_py_start_on = renewal_plan_year.start_on
      end
    end

    def plan_year_total_enrolled_count
      if load_plan_year.present?
        merge_model.plan_year.total_enrolled_count = load_plan_year.total_enrolled_count
      end
    end

    def plan_year_eligible_to_enroll_count
      if load_plan_year.present?
        merge_model.plan_year.eligible_to_enroll_count = load_plan_year.eligible_to_enroll_count
      end
    end

    def plan_year_renewal_py_end_on
      if renewal_plan_year.present?
        merge_model.plan_year.renewal_py_end_on = renewal_plan_year.end_on
      end
    end

    def plan_year_enrollment_errors
      if renewal_plan_year.present?
        merge_model.plan_year.enrollment_errors = renewal_plan_year.enrollment_errors
      elsif current_plan_year.present?
        merge_model.plan_year.enrollment_errors = current_plan_year.enrollment_errors
      end
    end

    def plan_year_warnings
      plan_year_warnings = []
      if current_plan_year.present?
        current_plan_year.application_eligibility_warnings.each do |k, _|
          case k.to_s
          when "fte_count"
            plan_year_warnings << "Full Time Equivalent must be 1-50"
          when "primary_office_location"
            plan_year_warnings << "primary business address not located in #{Settings.aca.state_name}"
          end
        end
      end
      merge_model.plan_year.warnings = plan_year_warnings.join(', ')
    end

    def load_plan_year
      plan_year = nil

      if payload['event_object_kind'].constantize == PlanYear
        plan_year = employer_profile.plan_years.find(payload['event_object_id'])
      end

      if plan_year.blank? && enrollment.present?
        if enrollment.benefit_group
          plan_year = enrollment.benefit_group.plan_year
        end
      end

      plan_year
    end

    def current_plan_year
      return @current_plan_year if defined? @current_plan_year
      plan_year = load_plan_year
      if plan_year.present?
        if plan_year.is_renewing? || plan_year.renewing_application_ineligible? || plan_year.renewing_canceled?
          @current_plan_year = employer_profile.plan_years.detect{|py| py.is_published? && py.start_on == plan_year.start_on.prev_year}
        else
          @current_plan_year = plan_year
        end
      end
    end

    def renewal_plan_year
      return @renewal_plan_year if defined? @renewal_plan_year
      plan_year = load_plan_year
      if plan_year.present?
        if plan_year.is_renewing? || plan_year.renewing_application_ineligible? || plan_year.renewing_canceled?
          @renewal_plan_year = plan_year
        else
          @renewal_plan_year = employer_profile.plan_years.detect{|py| py.is_published? && py.start_on == plan_year.start_on.prev_year}
        end
      end
    end

    def format_date(date)
      return if date.blank?
      date.strftime("%m/%d/%Y")
    end
  end
end