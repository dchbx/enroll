module Notifier
  module Builders::BenefitApplication
    include ActionView::Helpers::NumberHelper

    def benefit_application_current_py_start_date
      if current_benefit_application.present?
        merge_model.benefit_application.current_py_start_date = format_date(current_benefit_application.start_on)
      end
    end

    def benefit_application_current_py_start_date_plus_one_year
      return if current_benefit_application.blank?

      merge_model.benefit_application.current_py_start_date_plus_one_year = format_date(current_benefit_application.start_on.next_year)
    end

    def benefit_application_current_py_end_date
      if current_benefit_application.present?
        merge_model.benefit_application.current_py_end_date = format_date(current_benefit_application.end_on)
      end
    end

    def benefit_application_renewal_py_start_date
      return if renewal_benefit_application.blank?

      merge_model.benefit_application.renewal_py_start_date = format_date(renewal_benefit_application.start_on)
    end

    def benefit_application_current_year
      return if current_benefit_application.blank?

      merge_model.benefit_application.current_year = current_benefit_application.start_on.year.to_s
    end

    def benefit_application_renewal_year
      return if renewal_benefit_application.blank?

      merge_model.benefit_application.renewal_year = renewal_benefit_application.start_on.year.to_s
    end

    def benefit_application_next_available_start_date
      schedular =  BenefitSponsors::BenefitApplications::BenefitApplicationSchedular.new
      merge_model.benefit_application.next_available_start_date = schedular.calculate_start_on_dates.first.to_date
    end

    def benefit_application_next_application_deadline
      merge_model.benefit_application.next_application_deadline = Date.new(benefit_application_next_available_start_date.year, benefit_application_next_available_start_date.prev_month.month, Settings.aca.shop_market.initial_application.advertised_deadline_of_month)
    end

    def benefit_application_renewal_py_end_date
      if renewal_benefit_application.present?
        merge_model.benefit_application.renewal_py_end_date = format_date(renewal_benefit_application.end_on)
      end
    end

    def benefit_application_current_py_oe_start_date
      if current_benefit_application.present?
        merge_model.benefit_application.current_py_oe_start_date = format_date(current_benefit_application.open_enrollment_period.min)
      end
    end

    def benefit_application_monthly_employer_contribution_amount
      if current_benefit_application.present?
        employer_contribution_amount = []
        cost_estimator = census_employee_cost_estimator(current_benefit_application)
        current_benefit_application.benefit_packages.flat_map(&:sponsored_benefits).each do |sb|
          sbenefit, _price, _cont = cost_estimator.calculate(sb, sb.reference_product, sb.product_package)
          employer_contribution_amount << _cont.to_i
        end
        merge_model.benefit_application.monthly_employer_contribution_amount = number_to_currency(employer_contribution_amount.sum)
      end
    end

    def census_employee_cost_estimator(benefit_application)
      BenefitSponsors::SponsoredBenefits::CensusEmployeeCoverageCostEstimator.new(benefit_application.benefit_sponsorship, benefit_application.effective_period.min)
    end

    def benefit_application_current_py_plus_60_days
      if current_benefit_application.present?
        merge_model.benefit_application.current_py_plus_60_days = format_date(current_benefit_application.end_on + 60.days)
      end
    end

    def benefit_application_group_termination_plus_31_days
      return if load_benefit_application.blank?

      merge_model.benefit_application.group_termination_plus_31_days = format_date(load_benefit_application.end_on + 31.days)
    end

    def benefit_application_py_end_on_plus_60_days
      return if current_or_renewal_py.blank?

      merge_model.benefit_application.py_end_on_plus_60_days = format_date(current_or_renewal_py.end_on + 60.days)
    end

    def benefit_application_current_py_oe_end_date
      benefit_application =
        if ['zero_employees_on_roster_notice', 'low_enrollment_notice_for_employer', 'open_enrollment_end_reminder_notice_to_employee'].include? event_name
          load_benefit_application
        else
          current_benefit_application
        end
      return if benefit_application.blank?

      merge_model.benefit_application.current_py_oe_end_date = format_date(benefit_application.open_enrollment_end_on)
    end

    def benefit_application_renewal_py_oe_start_date
      if renewal_benefit_application.present?
        merge_model.benefit_application.renewal_py_oe_start_date = format_date(renewal_benefit_application.open_enrollment_period.min)
      end
    end

    def benefit_application_renewal_py_oe_end_date
      if renewal_benefit_application.present?
        merge_model.benefit_application.renewal_py_oe_end_date = format_date(renewal_benefit_application.open_enrollment_period.max)
      end
    end

    def benefit_application_initial_py_publish_advertise_deadline
      if current_benefit_application.present?
        prev_month = current_benefit_application.start_on.prev_month
        merge_model.benefit_application.initial_py_publish_advertise_deadline = format_date(Date.new(prev_month.year, prev_month.month, Settings.aca.shop_market.initial_application.advertised_deadline_of_month))
      end
    end

    def benefit_application_initial_py_publish_due_date
      if current_benefit_application.present?
        prev_month = current_benefit_application.start_on.prev_month
        merge_model.benefit_application.initial_py_publish_due_date = format_date(Date.new(prev_month.year, prev_month.month, Settings.aca.shop_market.initial_application.publish_due_day_of_month))
      end
    end

    def benefit_application_renewal_py_submit_soft_due_date
      if renewal_benefit_application.present?
        prev_month = renewal_benefit_application.start_on.prev_month
        merge_model.benefit_application.renewal_py_submit_soft_due_date = format_date(Date.new(prev_month.year, prev_month.month, Settings.aca.shop_market.renewal_application.application_submission_soft_deadline))
      end
    end

    def benefit_application_renewal_py_submit_due_date
      if renewal_benefit_application.present?
        prev_month = renewal_benefit_application.start_on.prev_month
        merge_model.benefit_application.renewal_py_submit_due_date = format_date(Date.new(prev_month.year, prev_month.month, Settings.aca.shop_market.renewal_application.publish_due_day_of_month))
      end
    end

    def benefit_application_binder_payment_due_date
      if current_benefit_application.present?
        schedular = BenefitSponsors::BenefitApplications::BenefitApplicationSchedular.new
        merge_model.benefit_application.binder_payment_due_date = format_date(schedular.map_binder_payment_due_date_by_start_on(current_benefit_application.start_on))
      end
    end

    def benefit_application_current_py_start_on
      if current_benefit_application.present?
        merge_model.benefit_application.current_py_start_on = current_benefit_application.start_on
      end
    end

    def benefit_application_current_py_end_on
      if current_benefit_application.present?
        merge_model.benefit_application.current_py_end_on = current_benefit_application.end_on
      end
    end

    def benefit_application_renewal_py_start_on
      if renewal_benefit_application.present?
        merge_model.benefit_application.renewal_py_start_on = renewal_benefit_application.start_on
      end
    end

    def benefit_application_total_enrolled_count
      if load_benefit_application.present?
        merge_model.benefit_application.total_enrolled_count = load_benefit_application.all_enrolled_and_waived_member_count
      end
    end

    def benefit_application_eligible_to_enroll_count
      if load_benefit_application.present?
        merge_model.benefit_application.eligible_to_enroll_count = load_benefit_application.members_eligible_to_enroll_count
      end
    end

    def benefit_application_renewal_py_end_on
      if renewal_benefit_application.present?
        merge_model.benefit_application.renewal_py_end_on = renewal_benefit_application.end_on
      end
    end

    def benefit_application_enrollment_errors
      enrollment_errors = []
      benefit_application = (renewal_benefit_application || current_benefit_application)
      return if benefit_application.blank?

      policy = enrollment_policy.business_policies_for(benefit_application, :end_open_enrollment)
      unless policy.is_satisfied?(benefit_application)
        policy.fail_results.each do |k, _|
          case k.to_s
          when 'minimum_eligible_member_count'
            enrollment_errors << 'at least one employee must be eligible to enroll'
          when 'non_business_owner_enrollment_count'
            enrollment_errors << "at least #{Settings.aca.shop_market.non_owner_participation_count_minimum} non-owner employee must enroll"
          when 'minimum_participation_rule'
            unless benefit_application.effective_date.yday == 1
              enrollment_errors << "number of eligible participants enrolling (#{benefit_application.all_enrolled_and_waived_member_count}) is less than minimum required #{benefit_application.minimum_enrolled_count}"
            end
          end
        end
      end
      merge_model.benefit_application.enrollment_errors = enrollment_errors.join(' AND/OR ')
    end

    def enrollment_policy
      return @enrollment_policy if defined? @enrollment_policy
      @enrollment_policy = BenefitSponsors::BenefitApplications::AcaShopEnrollmentEligibilityPolicy.new
    end

    def eligibility_policy
      return @eligibility_policy if defined? @eligibility_policy
      @eligibility_policy = BenefitSponsors::BenefitApplications::AcaShopApplicationEligibilityPolicy.new
    end

    def benefit_application_warnings
      benefit_application_warnings = []
      benefit_application = current_benefit_application || renewal_benefit_application
      if benefit_application.present?
        policy = eligibility_policy.business_policies_for(current_benefit_application, :submit_benefit_application)
        unless policy.is_satisfied?(current_benefit_application)
          policy.fail_results.each do |k, _|
            case k.to_s
            when "benefit_application_fte_count"
              benefit_application_warnings << "Full Time Equivalent must be 1-50"
            when "employer_primary_office_location"
              benefit_application_warnings << "primary business address not located in #{Settings.aca.state_name}"
            end
          end
        end
      end
      merge_model.benefit_application.warnings = benefit_application_warnings.join(', ')
    end

    def load_benefit_application
      benefit_application = nil
      if payload['event_object_kind'].constantize == BenefitSponsors::BenefitApplications::BenefitApplication
        benefit_application = employer_profile.active_benefit_sponsorship.benefit_applications.find(payload['event_object_id'])
      end

      if benefit_application.blank?
        benefit_application = enrollment.sponsored_benefit_package.benefit_application if enrollment.present? && enrollment.sponsored_benefit_package
        benefit_application = employer_profile.benefit_applications.published_or_renewing_published.first if event_name == 'out_of_pocker_url_notifier'
      end
      benefit_application
    end

    def current_benefit_application
      return @current_benefit_application if defined? @current_benefit_application
      benefit_application = load_benefit_application
      if benefit_application.present?
        if benefit_application.is_renewing? && (benefit_application.pending? || benefit_application.is_submitted? || benefit_application.canceled? || benefit_application.draft? || benefit_application.enrollment_ineligible?)
          @current_benefit_application = employer_profile.active_benefit_sponsorship.benefit_applications.detect{|ba| ba.is_submitted? && ba.end_on == benefit_application.start_on.to_date.prev_day}
        else
          @current_benefit_application = benefit_application
        end
      end
    end

    def renewal_benefit_application
      return @renewal_benefit_application if defined? @renewal_benefit_application
      benefit_application = load_benefit_application
      if benefit_application.present?
        if benefit_application.is_renewing? && (benefit_application.pending? || benefit_application.is_submitted? || benefit_application.canceled? || benefit_application.draft? || benefit_application.enrollment_ineligible?)
          @renewal_benefit_application = benefit_application
        else
          @renewal_benefit_application = employer_profile.active_benefit_sponsorship.benefit_applications.detect{|ba| (ba.is_submitted? || ba.draft?) && (ba.end_on == benefit_application.start_on.to_date.prev_day)}
        end
      end
    end

    def current_or_renewal_py
      current_benefit_application || renewal_benefit_application
    end

    def format_date(date)
      return if date.blank?
      date.strftime("%m/%d/%Y")
    end
  end
end
