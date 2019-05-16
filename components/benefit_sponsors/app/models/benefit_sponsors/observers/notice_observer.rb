module BenefitSponsors
  module Observers
    class NoticeObserver
      include ::Acapi::Notifiers

      attr_accessor :notifier

      def initialize
        @notifier = BenefitSponsors::Services::NoticeService.new
      end

      def deliver(recipient:, event_object:, notice_event:, notice_params: {})
        notifier.deliver(recipient: recipient, event_object: event_object, notice_event: notice_event, notice_params: notice_params)
      end

      def process_organization_events(_model_instance, model_event)
        raise ArgumentError, "expected BenefitSponsors::ModelEvents::ModelEvent" unless model_event.present? && model_event.is_a?(BenefitSponsors::ModelEvents::ModelEvent)

        method_name = "trigger_#{model_event.event_key}_notice"
        raise StandardError, "unable to find method name: #{method_name}" unless respond_to?(method_name)

        __send__(method_name, model_event)
      end

      def process_enrollment_events(_model_instance, model_event)
        raise ArgumentError, "expected BenefitSponsors::ModelEvents::ModelEvent" unless model_event.present? && model_event.is_a?(BenefitSponsors::ModelEvents::ModelEvent)

        hbx_enrollment = model_event.klass_instance
        return unless hbx_enrollment.is_shop?

        method_name = "trigger_#{model_event.event_key}_notice"
        raise StandardError, "unable to find method name: #{method_name}" unless respond_to?(method_name)

        __send__(method_name, hbx_enrollment)
      end

      def process_census_employee_events(_model_instance, model_event)
        raise ArgumentError, "expected BenefitSponsors::ModelEvents::ModelEvent" unless model_event.present? && model_event.is_a?(BenefitSponsors::ModelEvents::ModelEvent)

        census_employee = model_event.klass_instance

        method_name = "trigger_#{model_event.event_key}_notice"
        raise StandardError, "unable to find method name: #{method_name}" unless respond_to?(method_name)

        __send__(method_name, model_event, census_employee)
      end

      def process_employee_role_events(_model_instance, model_event)
        raise ArgumentError, "expected BenefitSponsors::ModelEvents::ModelEvent" unless model_event.present? && model_event.is_a?(BenefitSponsors::ModelEvents::ModelEvent)

        method_name = "trigger_#{model_event.event_key}_notice"
        raise StandardError, "unable to find method name: #{method_name}" unless respond_to?(method_name)

        __send__(method_name, model_event)
      end

      def process_broker_agency_events(_model_instance, model_event)
        raise ArgumentError, "expected BenefitSponsors::ModelEvents::ModelEvent" unless model_event.present? && model_event.is_a?(BenefitSponsors::ModelEvents::ModelEvent)

        broker_agency_account = model_event.klass_instance
        return if  broker_agency_account.benefit_sponsorship.blank?

        method_name = "trigger_#{model_event.event_key}_notice"
        raise StandardError, "unable to find method name: #{method_name}" unless respond_to?(method_name)

        __send__(method_name, model_event)
      end

      def process_special_enrollment_events(_model_instance, model_event)
        raise ArgumentError, "expected BenefitSponsors::ModelEvents::ModelEvent" unless model_event.present? && model_event.is_a?(BenefitSponsors::ModelEvents::ModelEvent)

        method_name = "trigger_#{model_event.event_key}_notice"
        raise StandardError, "unable to find method name: #{method_name}" unless respond_to?(method_name)

        __send__(method_name, model_event)
      end

      def process_document_events(_model_instance, model_event)
        raise ArgumentError, "expected BenefitSponsors::ModelEvents::ModelEvent" unless model_event.present? && model_event.is_a?(BenefitSponsors::ModelEvents::ModelEvent)

        document = model_event.klass_instance
        employer_profile = document.documentable
        eligible_states = BenefitSponsors::BenefitApplications::BenefitApplication::PUBLISHED_STATES
        benefit_application = employer_profile.latest_benefit_sponsorship.benefit_applications.where(:aasm_state.in => eligible_states).first

        method_name = "trigger_#{model_event.event_key}_notice"
        raise StandardError, "unable to find method name: #{method_name}" unless respond_to?(method_name)

        __send__(method_name, benefit_application, employer_profile)
      end

      def process_application_events(_model_instance, model_event)
        raise ArgumentError, "expected BenefitSponsors::ModelEvents::ModelEvent" unless model_event.present? && model_event.is_a?(BenefitSponsors::ModelEvents::ModelEvent)

        method_name = "trigger_#{model_event.event_key}_notice"
        raise StandardError, "unable to find method name: #{method_name}" unless respond_to?(method_name)

        __send__(method_name, model_event)
      end

      def process_employer_profile_events(_model_instance, model_event)
        raise ArgumentError, "expected BenefitSponsors::ModelEvents::ModelEvent" unless model_event.present? && model_event.is_a?(BenefitSponsors::ModelEvents::ModelEvent)

        method_name = "trigger_#{model_event.event_key}"
        raise StandardError, "unable to find method name: #{method_name}" unless respond_to?(method_name)

        __send__(method_name, model_event)
      end

      def process_benefit_sponsorship_events(_model_instance, model_event)
        raise ArgumentError, "expected BenefitSponsors::ModelEvents::ModelEvent" unless model_event.present? && model_event.is_a?(BenefitSponsors::ModelEvents::ModelEvent)

        method_name = "trigger_#{model_event.event_key}_notice"
        raise StandardError, "unable to find method name: #{method_name}" unless respond_to?(method_name)

        __send__(method_name, model_event)
      end

      def trigger_welcome_notice_to_employer_notice(model_event)
        employer_profile = model_event.klass_instance.employer_profile
        deliver(recipient: employer_profile, event_object: employer_profile, notice_event: "welcome_notice_to_employer")
      end

      def trigger_application_coverage_selected_notice(hbx_enrollment)
        return unless hbx_enrollment.is_shop? && hbx_enrollment.census_employee.is_active?

        open_enrollment_period = hbx_enrollment.sponsored_benefit_package.benefit_application.open_enrollment_period
        is_valid_employer_py_oe = (open_enrollment_period.cover?(hbx_enrollment.submitted_at) || open_enrollment_period.cover?(hbx_enrollment.created_at))

        deliver(recipient: hbx_enrollment.employee_role, event_object: hbx_enrollment, notice_event: "notify_employee_of_plan_selection_in_open_enrollment") if is_valid_employer_py_oe

        return unless !is_valid_employer_py_oe && (hbx_enrollment.enrollment_kind == "special_enrollment" || hbx_enrollment.census_employee.new_hire_enrollment_period.cover?(TimeKeeper.date_of_record))

        deliver(recipient: hbx_enrollment.employer_profile, event_object: hbx_enrollment, notice_event: "employee_mid_year_plan_change_non_congressional_notice")
        deliver(recipient: hbx_enrollment.employee_role, event_object: hbx_enrollment, notice_event: "employee_plan_selection_confirmation_sep_new_hire")
      end

      # def trigger_employee_waiver_confirmation_notice(hbx_enrollment)
      #    deliver(recipient: hbx_enrollment.employee_role, event_object: hbx_enrollment, notice_event: "employee_waiver_confirmation")
      # end

      def trigger_employee_coverage_termination_notice(hbx_enrollment)
        return unless hbx_enrollment.is_shop? && (::CensusEmployee::EMPLOYMENT_ACTIVE_STATES - ::CensusEmployee::PENDING_STATES).include?(hbx_enrollment.census_employee.aasm_state) && hbx_enrollment.sponsored_benefit_package.is_active

        benefit_application = hbx_enrollment.sponsored_benefit_package.benefit_application
        return if benefit_application.termination_pending? || benefit_application.terminated?

        deliver(recipient: hbx_enrollment.employer_profile, event_object: hbx_enrollment, notice_event: "employer_notice_for_employee_coverage_termination")
        deliver(recipient: hbx_enrollment.employee_role, event_object: hbx_enrollment, notice_event: "employee_notice_for_employee_coverage_termination")
      end

      def trigger_employee_terminated_from_roster_notice(_model_event, census_employee)
        deliver(recipient: census_employee.employee_role, event_object: census_employee, notice_event: "employee_notice_for_employee_terminated_from_roster")
      end

      def trigger_employee_coverage_passively_waived_notice(model_event, census_employee)
        deliver(recipient: census_employee.employee_role, event_object: model_event.options[:event_object], notice_event: "employee_coverage_passively_waived")
      end

      def trigger_employee_coverage_passively_renewed_notice(model_event, census_employee)
        deliver(recipient: census_employee.employee_role, event_object: model_event.options[:event_object], notice_event: "employee_coverage_passively_renewed")
      end

      def trigger_employee_coverage_passive_renewal_failed_notice(model_event, census_employee)
        deliver(recipient: census_employee.employee_role, event_object: model_event.options[:event_object], notice_event: "employee_coverage_passive_renewal_failed")
      end

      def trigger_employee_matches_employer_roster_notice(model_event)
        employee_role = model_event.klass_instance
        deliver(recipient: employee_role, event_object: employee_role.census_employee, notice_event: "employee_matches_employer_roster")
      end

      def trigger_application_submitted_notice(model_event)
        benefit_application = model_event.klass_instance
        trigger_zero_employees_on_roster_notice(benefit_application)
        if benefit_application.is_renewing?
          deliver(recipient: benefit_application.employer_profile, event_object: benefit_application, notice_event: "renewal_application_submitted")
        else
          deliver(recipient: benefit_application.employer_profile, event_object: benefit_application, notice_event: "initial_application_submitted")
        end
      end

      def trigger_employer_open_enrollment_completed_notice(model_event)
        benefit_application = model_event.klass_instance
        policy = enrollment_policy.business_policies_for(benefit_application, :end_open_enrollment)
        return unless policy.is_satisfied?(benefit_application)

        notice_event = benefit_application.is_renewing? ? "renewal_employer_open_enrollment_completed" : "initial_employer_open_enrollment_completed"
        deliver(recipient: benefit_application.employer_profile, event_object: benefit_application, notice_event: notice_event)

        return unless benefit_application.is_renewing?

        benefit_application.benefit_sponsorship.census_employees.non_terminated.each do |ce|
          enrollments = ce.renewal_benefit_group_assignment.hbx_enrollments
          enrollment = enrollments.select{ |enr| (HbxEnrollment::ENROLLED_STATUSES + HbxEnrollment::RENEWAL_STATUSES).include?(enr.aasm_state) }.max_by(&:updated_at)
          deliver(recipient: enrollment.employee_role, event_object: enrollment, notice_event: "renewal_employee_enrollment_confirmation") if enrollment.employee_role.present?
        end
      end

      def trigger_ineligible_application_submitted_notice(model_event)
        benefit_application = model_event.klass_instance
        policy = eligibility_policy.business_policies_for(benefit_application, :submit_benefit_application)
        return if policy.is_satisfied?(benefit_application)

        if benefit_application.is_renewing?
          return unless policy.fail_results.include?(:employer_primary_office_location)

          deliver(recipient: benefit_application.employer_profile, event_object: benefit_application, notice_event: "employer_renewal_eligibility_denial_notice")
          benefit_application.benefit_sponsorship.census_employees.non_terminated.each do |ce|
            deliver(recipient: ce.employee_role, event_object: benefit_application, notice_event: "termination_of_employers_health_coverage") if ce.employee_role.present?
          end
        elsif policy.fail_results.include?(:employer_primary_office_location) || policy.fail_results.include?(:benefit_application_fte_count)
          deliver(recipient: benefit_application.employer_profile, event_object: benefit_application, notice_event: "employer_initial_eligibility_denial_notice")
        end
      end

      def trigger_application_denied_notice(model_event)
        benefit_application = model_event.klass_instance
        policy = enrollment_policy.business_policies_for(benefit_application, :end_open_enrollment)
        return if policy.is_satisfied?(benefit_application)

        return unless policy.fail_results.include?(:minimum_participation_rule) || policy.fail_results.include?(:non_business_owner_enrollment_count)

        employer_notice_event = benefit_application.is_renewing? ? "renewal_employer_ineligibility_notice" : "initial_employer_application_denied"
        employee_notice_event = benefit_application.is_renewing? ? "employee_renewal_employer_ineligibility_notice" : "group_ineligibility_notice_to_employee"
        deliver(recipient: benefit_application.employer_profile, event_object: benefit_application, notice_event: employer_notice_event)

        benefit_application.benefit_sponsorship.census_employees.non_terminated.each do |ce|
          deliver(recipient: ce.employee_role, event_object: benefit_application, notice_event: employee_notice_event) if ce.employee_role.present?
        end
      end

      def trigger_renewal_application_created_notice(model_event)
        benefit_application = model_event.klass_instance
        employer_profile = benefit_application.employer_profile
        if employer_profile.is_converting?
          deliver(recipient: employer_profile, event_object: benefit_application, notice_event: "conversion_group_renewal")
        else
          deliver(recipient: employer_profile, event_object: benefit_application, notice_event: "renewal_application_created")
        end
      end

      def trigger_renewal_application_autosubmitted_notice(model_event)
        benefit_application = model_event.klass_instance
        deliver(recipient: benefit_application.employer_profile, event_object: benefit_application, notice_event: "renewal_application_autosubmitted") if benefit_application.is_renewing?
        trigger_zero_employees_on_roster_notice(benefit_application)
      end

      def trigger_initial_employer_first_reminder_to_publish_plan_year_notice(_model_event)
        start_on = (TimeKeeper.date_of_record + 2.months).beginning_of_month
        BenefitSponsors::Queries::NoticeQueries.initial_employers_by_effective_on_and_state(start_on: start_on, aasm_state: :draft).each do |benefit_sponsorship|
          benefit_application = benefit_sponsorship.benefit_applications.where(:aasm_state => :draft).max_by(&:created_at)
          next if benefit_application.is_renewing?

          deliver(recipient: benefit_sponsorship.profile, event_object: benefit_application, notice_event: "initial_employer_first_reminder_to_publish_plan_year")
        end
      end

      def trigger_initial_employer_second_reminder_to_publish_plan_year_notice(_model_event)
        start_on = (TimeKeeper.date_of_record + 2.months).beginning_of_month
        BenefitSponsors::Queries::NoticeQueries.initial_employers_by_effective_on_and_state(start_on: start_on, aasm_state: :draft).each do |benefit_sponsorship|
          benefit_application = benefit_sponsorship.benefit_applications.where(:aasm_state => :draft).max_by(&:created_at)
          next if benefit_application.is_renewing?

          deliver(recipient: benefit_sponsorship.profile, event_object: benefit_application, notice_event: "initial_employer_second_reminder_to_publish_plan_year")
        end
      end

      def trigger_initial_employer_final_reminder_to_publish_plan_year_notice(_model_event)
        start_on = TimeKeeper.date_of_record.next_month.beginning_of_month
        BenefitSponsors::Queries::NoticeQueries.initial_employers_by_effective_on_and_state(start_on: start_on, aasm_state: :draft).each do |benefit_sponsorship|
          benefit_application = benefit_sponsorship.benefit_applications.where(:aasm_state => :draft).max_by(&:created_at)
          next if benefit_application.is_renewing?

          deliver(recipient: benefit_sponsorship.profile, event_object: benefit_application, notice_event: "initial_employer_final_reminder_to_publish_plan_year")
        end
      end

      def trigger_renewal_employer_first_reminder_to_publish_plan_year_notice(_model_event)
        BenefitSponsors::Queries::NoticeQueries.organizations_for_force_publish(TimeKeeper.date_of_record).each do |benefit_sponsorship|
          benefit_application = benefit_sponsorship.benefit_applications.where(:aasm_state => :draft).detect(&:is_renewing?)
          next unless benefit_application.present? && benefit_application.is_renewing?

          deliver(recipient: benefit_sponsorship.profile, event_object: benefit_application, notice_event: "renewal_employer_first_reminder_to_publish_plan_year")
        end
      end

      def trigger_renewal_employer_second_reminder_to_publish_plan_year_notice(_model_event)
        BenefitSponsors::Queries::NoticeQueries.organizations_for_force_publish(TimeKeeper.date_of_record).each do |benefit_sponsorship|
          benefit_application = benefit_sponsorship.benefit_applications.where(:aasm_state => :draft).detect(&:is_renewing?)
          next unless benefit_application.present? && benefit_application.is_renewing?

          deliver(recipient: benefit_sponsorship.profile, event_object: benefit_application, notice_event: "renewal_employer_second_reminder_to_publish_plan_year")
        end
      end

      def trigger_renewal_employer_third_reminder_to_publish_plan_year_notice(_model_event)
        BenefitSponsors::Queries::NoticeQueries.organizations_for_force_publish(TimeKeeper.date_of_record).each do |benefit_sponsorship|
          benefit_application = benefit_sponsorship.benefit_applications.where(:aasm_state => :draft).detect(&:is_renewing?)
          next unless benefit_application.present? && benefit_application.is_renewing?

          deliver(recipient: benefit_sponsorship.profile, event_object: benefit_application, notice_event: "renewal_employer_third_reminder_to_publish_plan_year")
        end
      end

      def trigger_initial_employer_no_binder_payment_received_notice(_model_event)
        BenefitSponsors::Queries::NoticeQueries.initial_employers_in_ineligible_state.each do |benefit_sponsorship|
          next unless benefit_sponsorship.initial_enrollment_ineligible?

          benefit_application = benefit_sponsorship.benefit_applications.where(:aasm_state => :enrollment_ineligible).first
          next unless benefit_application.present? && !benefit_application.is_renewing?

          #Notice to employer for missing binder payment
          deliver(recipient: benefit_application.employer_profile, event_object: benefit_application, notice_event: "initial_employer_no_binder_payment_received")

          benefit_sponsorship.census_employees.active.each do |ce|
            #Notice to employee that there employer misses binder payment
            deliver(recipient: ce.employee_role, event_object: benefit_application, notice_event: "notice_to_ee_that_er_plan_year_will_not_be_written") if ce.employee_role
          end
        end
      end

      def trigger_group_advance_termination_confirmation_notice(model_event)
        benefit_application = model_event.klass_instance
        deliver(recipient: benefit_application.employer_profile, event_object: benefit_application, notice_event: "group_advance_termination_confirmation")

        benefit_application.benefit_sponsorship.census_employees.non_terminated.each do |ce|
          deliver(recipient: ce.employee_role, event_object: benefit_application, notice_event: "notify_employee_of_group_advance_termination") if ce.employee_role
        end
      end

      def trigger_open_enrollment_end_reminder_and_low_enrollment_notice(_model_event)
        date = TimeKeeper.date_of_record
        BenefitSponsors::Queries::NoticeQueries.organizations_ending_oe_in_two_days(date).each do |benefit_sponsorship|
          benefit_application = benefit_sponsorship.benefit_applications.where(:aasm_state => :enrollment_open).max_by(&:created_at)
          benefit_sponsorship.census_employees.non_terminated.each do |ce|
            #exclude new hires
            next if ce.new_hire_enrollment_period.cover?(date) || ce.new_hire_enrollment_period.first > date

            deliver(recipient: ce.employee_role, event_object: benefit_application, notice_event: "employee_open_enrollment_reminder") if ce.employee_role
          rescue StandardError => e
            (Rails.logger.error { "Unable to deliver open enrollment reminder notice to #{ce.full_name} due to #{e}" }) unless Rails.env.test?
          end
          next if benefit_application.effective_period.min.yday == 1

          next unless benefit_application.enrollment_ratio < benefit_application.benefit_market.configuration.ee_ratio_min

          deliver(recipient: benefit_sponsorship.profile, event_object: benefit_application, notice_event: "low_enrollment_notice_for_employer")
        end
      end

      def trigger_zero_employees_on_roster_notice(benefit_application)
        return unless benefit_application.benefit_sponsorship.census_employees.active.count < 1

        deliver(recipient: benefit_application.sponsor_profile, event_object: benefit_application, notice_event: "zero_employees_on_roster_notice")
      end

      def trigger_broker_hired_notice(model_event)
        broker_agency_account = model_event.klass_instance
        broker_agency_profile = broker_agency_account.broker_agency_profile
        broker = broker_agency_profile.primary_broker_role
        employer_profile = broker_agency_account.benefit_sponsorship.profile

        deliver(recipient: broker, event_object: employer_profile, notice_event: "broker_hired_notice_to_broker")
        deliver(recipient: broker_agency_profile, event_object: employer_profile, notice_event: "broker_agency_hired_confirmation")
        deliver(recipient: employer_profile, event_object: employer_profile, notice_event: "broker_hired_confirmation_to_employer")
      end

      def trigger_broker_fired_notice(model_event)
        broker_agency_account = model_event.klass_instance
        broker_agency_profile = broker_agency_account.broker_agency_profile
        broker = broker_agency_profile.primary_broker_role
        employer_profile = broker_agency_account.benefit_sponsorship.profile

        deliver(recipient: broker, event_object: employer_profile, notice_event: "broker_fired_confirmation_to_broker")
        deliver(recipient: broker_agency_profile, event_object: employer_profile, notice_event: "broker_agency_fired_confirmation")
        deliver(recipient: employer_profile, event_object: broker_agency_account, notice_event: "broker_fired_confirmation_to_employer")
      end

      def trigger_generate_initial_employer_invoice(model_event)
        employer_profile = model_event.klass_instance
        submitted_states = BenefitSponsors::BenefitApplications::BenefitApplication::SUBMITTED_STATES - [:termination_pending]
        benefit_application = employer_profile.benefit_applications.where(:aasm_state.in => submitted_states).max_by(&:created_at)
        deliver(recipient: employer_profile, event_object: benefit_application, notice_event: "generate_initial_employer_invoice") if benefit_application.present?
      end

      def trigger_initial_employee_plan_selection_confirmation_notice(model_event)
        benefit_sponsorship = model_event.klass_instance
        employer_profile = benefit_sponsorship.profile
        return unless employer_profile.is_new_employer?

        census_employees = benefit_sponsorship.census_employees.non_terminated
        census_employees.each do |ce|
          enrollment = ce.active_benefit_group_assignment.hbx_enrollment
          effective_on = employer_profile.active_benefit_sponsorship.benefit_applications.where(:aasm_state.in => [:enrollment_eligible, :enrollment_closed]).first.start_on
          next unless enrollment.present? && enrollment.effective_on == effective_on

          deliver(recipient: ce.employee_role, event_object: ce, notice_event: "initial_employee_plan_selection_confirmation")
        end
      end

      def trigger_employee_sep_request_accepted_notice(model_event)
        special_enrollment_period = model_event.klass_instance
        return unless special_enrollment_period.is_shop?

        person = special_enrollment_period.family.primary_applicant.person
        return unless (employee_role = person.active_employee_roles[0])

        event_name = person.has_multiple_active_employers? ? 'sep_accepted_notice_for_ee_active_on_multiple_rosters' : 'sep_accepted_notice_for_ee_active_on_single_roster'
        deliver(recipient: employee_role, event_object: special_enrollment_period, notice_event: event_name)
      end

      def trigger_initial_employer_invoice_available_notice(benefit_application, employer_profile)
        deliver(recipient: employer_profile, event_object: benefit_application, notice_event: "initial_employer_invoice_available")
      end

      def trigger_employer_invoice_available_notice(benefit_application, employer_profile)
        deliver(recipient: employer_profile, event_object: benefit_application, notice_event: "employer_invoice_available_notice")
      end

      def ridp_document_update; end

      def vlp_document_update; end

      def paper_application_update; end

      def employer_attestation_document_update; end

      def employer_profile_date_change; end

      def hbx_enrollment_date_change; end

      def census_employee_date_change; end

      def document_date_change; end

      def special_enrollment_period_date_change; end

      def broker_agency_account_date_change; end

      private

      def eligibility_policy
        return @eligibility_policy if defined? @eligibility_policy

        @eligibility_policy = BenefitSponsors::BenefitApplications::AcaShopApplicationEligibilityPolicy.new
      end

      def enrollment_policy
        return @enrollment_policy if defined? @enrollment_policy

        @enrollment_policy = BenefitSponsors::BenefitApplications::AcaShopEnrollmentEligibilityPolicy.new
      end
    end
  end
end