# frozen_string_literal: true

module BenefitSponsors
  module BenefitApplications
    class AcaShopOpenEnrollmentService

      # Observer pattern tied to DateKeeper - Standard Event: OpenEnrollmentClosed
      # Needs to handle exempt applcations


#      BenefitSponsorships.may_begin_open_enrollment?
#      BenefitSponsorships.may_end_open_enrollment?

#      BenefitSponsorships.may_begin_benefit_coverage?

#      BenefitSponsorships.may_renew_application?

#      BenefitSponsorships.may_terminate_benefit_coverage?
#      BenefitSponsorships.may_reinstate_benefit_coverage?


#      BenefitApplication.can_renew?
#      BenefitApplication.is_renewing?

#      BenefitApplication.is_plan_design_eligible?
#      BenefitApplication.is_open_enrollment_enrollment_eligible?
#      BenefitApplication.is_benefit_coverage_begin_eligible?

#      BenefitApplication.can_begin_open_enrollment?
#      BenefitApplication.can_end_open_enrollment?
#      BenefitApplication.can_begin_benefit_coverage?
#      BenefitApplication.can_end_benefit_coverage?


      def initialize(benefit_application)
        @benefit_application = benefit_application
      end

      ## Trigger events can be dates or from UI
      def open_enrollments_past_end_on(_date = TimeKeeper.date_of_record)
        # query all benefit_applications in OE state with open_enrollment_period.max < date
        @benefit_applications = BenefitSponsors::BenefitApplications::BenefitApplication.by_open_enrollment_end_date

        @benefit_applications.each do |application|
          application.advance_date! if application&.may_advance_date?
        end
      end

      def begin_open_enrollment(benefit_application)
        if benefit_application&.may_advance_date?
          benefit_application.advance_date!
          member_enrollments.each { |_enrollment| renew_member_enrollment(benefit_application) } # Currently its attached to aasm callback
        end
      end

      def close_open_enrollment(_benefit_application)
        @benefit_applications = BenefitSponsors::BenefitApplications::BenefitApplication.by_open_enrollment_end_date

        @benefit_applications.each do |application|
          application.advance_date! if application&.may_advance_date?
        end
      end

      def cancel_open_enrollment(benefit_application); end

      # Exempt exception handling situation
      def extend_open_enrollment(benefit_application, new_end_date); end

      # Exempt exception handling situation
      def retroactive_open_enrollment(benefit_application); end

      def renew_member_enrollment(_renewal_benefit_application, _current_member_enrollment)
        renewal_member_enrollment
      end





      private


      def due_date_for_publish
        if benefit_sponsorship.benefit_applications.renewing.any?
          Date.new(start_on.prev_month.year, start_on.prev_month.month, Settings.aca.shop_market.renewal_application.publish_due_day_of_month)
        else
          Date.new(start_on.prev_month.year, start_on.prev_month.month, Settings.aca.shop_market.initial_application.publish_due_day_of_month)
        end
      end

      def is_application_eligible?
        application_eligibility_warnings.blank?
      end

      def is_publish_date_valid?
        event_name = aasm.current_event.to_s.gsub(/!/, '')
        event_name == "force_publish" ? true : (TimeKeeper.datetime_of_record <= due_date_for_publish.end_of_day)
      end

      #TODO: FIX this
      def assigned_census_employees_without_owner
        benefit_packages #.flat_map(){ |benefit_package| benefit_package.census_employees.active.non_business_owner }
      end

      def open_enrollment_date_errors
        errors = {}

        if is_renewing?
          minimum_length = Settings.aca.shop_market.renewal_application.open_enrollment.minimum_length.days
          enrollment_end = Settings.aca.shop_market.renewal_application.monthly_open_enrollment_end_on
        else
          minimum_length = Settings.aca.shop_market.open_enrollment.minimum_length.days
          enrollment_end = Settings.aca.shop_market.open_enrollment.monthly_end_on
        end

        log_message(errors) {{open_enrollment_period: "Open Enrollment period is shorter than minimum (#{minimum_length} days)"}} if (open_enrollment_end_on - (open_enrollment_start_on - 1.day)).to_i < minimum_length

        if open_enrollment_end_on > Date.new(start_on.prev_month.year, start_on.prev_month.month, enrollment_end)
          log_message(errors) {{open_enrollment_period: "Open Enrollment must end on or before the #{enrollment_end.ordinalize} day of the month prior to effective date"}}
        end

        errors
      end

      # Check plan year for violations of model integrity relative to publishing
      def application_errors
        errors = {}

        if open_enrollment_end_on > (open_enrollment_start_on + Settings.aca.shop_market.open_enrollment.maximum_length.months.months)
          log_message(errors){{open_enrollment_period: "Open Enrollment period is longer than maximum (#{Settings.aca.shop_market.open_enrollment.maximum_length.months} months)"}}
        end

        # if benefit_packages.any?{|bg| bg.reference_plan_id.blank? }
        #   log_message(errors){{benefit_packages: "Reference plans have not been selected for benefit packages. Please edit the benefit application and select reference plans."}}
        # end

        log_message(errors) {{benefit_packages: "You must create at least one benefit package to publish a plan year"}} if benefit_packages.blank?

        # if benefit_sponsorship.census_employees.active.to_set != assigned_census_employees.to_set
        #   log_message(errors) {{benefit_packages: "Every employee must be assigned to a benefit package defined for the published plan year"}}
        # end

        log_message(errors) {{benefit_sponsorship:  "This employer is ineligible to enroll for coverage at this time"}} if benefit_sponsorship.ineligible?

        log_message(errors) {{ publish: "You may only have one published benefit application at a time" }} if overlapping_published_plan_year?

        log_message(errors) {{publish: "Plan year starting on #{start_on.strftime('%m-%d-%Y')} must be published by #{due_date_for_publish.strftime('%m-%d-%Y')}"}} unless is_publish_date_valid?

        errors
      end

      # Check plan year application for regulatory compliance
      def application_eligibility_warnings
        warnings = {}
        unless benefit_sponsorship.profile.is_primary_office_local?
          warnings.merge!({primary_office_location: "Has its principal business address in the #{Settings.aca.state_name} and offers coverage to all full time employees through #{Settings.site.short_name} or Offers coverage through #{Settings.site.short_name} to all full time employees whose Primary worksite is located in the #{Settings.aca.state_name}"})
        end

        # Application is in ineligible state from prior enrollment activity
        warnings.merge!({ineligible: "Application did not meet eligibility requirements for enrollment"}) if aasm_state == "application_ineligible" || aasm_state == "renewing_application_ineligible"

        # Maximum company size at time of initial registration on the HBX
        warnings.merge!({ fte_count: "Has #{Settings.aca.shop_market.small_market_employee_count_maximum} or fewer full time equivalent employees" }) if !is_renewing? && (fte_count > Settings.aca.shop_market.small_market_employee_count_maximum)

        # Exclude Jan 1 effective date from certain checks
        unless effective_date.yday == 1
          # Employer contribution toward employee premium must meet minimum
          # TODO: FIX this once minimum_employer_contribution is fixed
          # if benefit_packages.size > 0 && (minimum_employer_contribution < Settings.aca.shop_market.employer_contribution_percent_minimum)
            # warnings.merge!({ minimum_employer_contribution:  "Employer contribution percent toward employee premium (#{minimum_employer_contribution.to_i}%) is less than minimum allowed (#{Settings.aca.shop_market.employer_contribution_percent_minimum.to_i}%)" })
          # end
        end

        warnings
      end

      # TODO: review this
      def validate_application_dates
        return if canceled? || expired? || renewing_canceled?
        return if effective_period.blank? || open_enrollment_period.blank?
        # return if imported_plan_year

        errors.add(:effective_period, "start date must be first day of the month") if effective_period.begin.mday != effective_period.begin.beginning_of_month.mday

        errors.add(:effective_period, "must be last day of the month") if effective_period.end.mday != effective_period.end.end_of_month.mday

        if effective_period.end > effective_period.begin.years_since(Settings.aca.shop_market.benefit_period.length_maximum.year)
          errors.add(:effective_period, "benefit period may not exceed #{Settings.aca.shop_market.benefit_period.length_maximum.year} year")
        end

        errors.add(:effective_period, "start date can't occur before open enrollment end date") if open_enrollment_period.end > effective_period.begin

        errors.add(:open_enrollment_period, "can't occur before open enrollment start date") if open_enrollment_period.end < open_enrollment_period.begin

        errors.add(:open_enrollment_period, "can't occur earlier than 60 days before start date") if open_enrollment_period.begin < (effective_period.begin - Settings.aca.shop_market.open_enrollment.maximum_length.months.months)

        if open_enrollment_period.end > (open_enrollment_period.begin + Settings.aca.shop_market.open_enrollment.maximum_length.months.months)
          errors.add(:open_enrollment_period, "open enrollment period is greater than maximum: #{Settings.aca.shop_market.open_enrollment.maximum_length.months} months")
        end

        ## Leave this validation disabled in the BQT??
        # if (effective_period.begin + Settings.aca.shop_market.initial_application.earliest_start_prior_to_effective_on.months.months) > TimeKeeper.date_of_record
        #   errors.add(:effective_period, "may not start application before " \
        #              "#{(effective_period.begin + Settings.aca.shop_market.initial_application.earliest_start_prior_to_effective_on.months.months).to_date} with #{effective_period.begin} effective date")
        # end

        unless ['canceled', 'suspended', 'terminated'].include?(aasm_state)
          #groups terminated for non-payment get 31 more days of coverage from their paid through date
          errors.add(:end_on, "must be last day of the month") if end_on != end_on.end_of_month

          if end_on != (start_on + Settings.aca.shop_market.benefit_period.length_minimum.year.years - 1.day)
            errors.add(:end_on, "plan year period should be: #{duration_in_days(Settings.aca.shop_market.benefit_period.length_minimum.year.years - 1.day)} days")
          end
        end
      end
    end
  end
end
