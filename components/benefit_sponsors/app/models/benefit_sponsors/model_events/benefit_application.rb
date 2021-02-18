# frozen_string_literal: true

# rubocop:disable Lint/UselessAssignment
module BenefitSponsors
  module ModelEvents
    module BenefitApplication

      APPLICATION_EXCEPTION_STATES  = [:pending, :assigned, :processing, :reviewing, :information_needed, :appealing].freeze

      REGISTERED_EVENTS_ON_SAVE = [
        :application_submitted,
        :ineligible_application_submitted,
        :employer_open_enrollment_completed,
        :application_denied,
        :renewal_application_autosubmitted,
        :initial_employee_plan_selection_confirmation,
        :group_termination_confirmation_notice
      ].freeze

      REGISTERED_EVENTS_ON_CREATE = [
        :renewal_application_created
      ].freeze

      EMPLOYER_EDI_EVENTS_ON_SAVE = [
        :benefit_coverage_period_terminated_nonpayment,
        :benefit_coverage_period_terminated_voluntary,
        :benefit_coverage_renewal_carrier_dropped,
        :benefit_coverage_period_reinstated
      ].freeze

      DATE_CHANGE_EVENTS = [
        :renewal_employer_first_reminder_to_publish_plan_year,
        :renewal_employer_second_reminder_to_publish_plan_year,
        :renewal_employer_third_reminder_to_publish_plan_year,
        :initial_employer_no_binder_payment_received,
        :initial_employer_first_reminder_to_publish_plan_year,
        :initial_employer_second_reminder_to_publish_plan_year,
        :initial_employer_final_reminder_to_publish_plan_year,
        :open_enrollment_end_reminder_and_low_enrollment
      ].freeze

      OTHER_EVENTS = [].freeze

      # Events triggered by state changes on individual instances
      def notify_on_save
        return if self.is_conversion?
        if aasm_state_changed?

          if is_transition_matching?(to: :enrollment_closed, from: [:enrollment_open, :enrollment_extended], event: :end_open_enrollment)
            is_employer_open_enrollment_completed = true
          end

          if is_transition_matching?(to: :pending, from: :draft, event: :submit_for_review)
            is_ineligible_application_submitted = true
          end

          if is_transition_matching?(to: :approved, from: [:draft, :imported] + BenefitSponsors::BenefitApplications::BenefitApplication::APPLICATION_EXCEPTION_STATES, event: :approve_application)
            is_application_submitted = true
          end

          if is_transition_matching?(to: :enrollment_ineligible, from: BenefitSponsors::BenefitApplications::BenefitApplication::ENROLLING_STATES, event: :deny_enrollment_eligiblity)
            is_application_denied = true
          end

          is_initial_employee_plan_selection_confirmation = true if is_transition_matching?(to: :binder_paid, from: :enrollment_closed, event: :credit_binder)

          if is_transition_matching?(to: [:terminated, :termination_pending], from: [:active, :suspended, :expired], event: [:terminate_enrollment, :schedule_enrollment_termination])
            is_group_termination_confirmation_notice = true
            is_benefit_coverage_period_terminated_voluntary = true if termination_kind.to_s == "voluntary"
            is_benefit_coverage_period_terminated_nonpayment = true if termination_kind.to_s == "nonpayment"
          end

          is_benefit_coverage_renewal_carrier_dropped = true if is_transition_matching?(to: [:canceled, :retroactive_canceled], from: [:enrollment_eligible, :active, :binder_paid], event: :cancel)
          is_benefit_coverage_period_reinstated = true if is_transition_matching?(to: :active, from: :reinstated, event: :activate_enrollment)
          if is_transition_matching?(to: :approved, from: [:draft, :imported] + BenefitSponsors::BenefitApplications::BenefitApplication::APPLICATION_EXCEPTION_STATES, event: :auto_approve_application)
            is_renewal_application_autosubmitted = true
          end

          # TODO -- encapsulated notify_observers to recover from errors raised by any of the observers
          (REGISTERED_EVENTS_ON_SAVE + EMPLOYER_EDI_EVENTS_ON_SAVE).each do |event|
            next unless (event_fired = instance_eval("is_" + event.to_s))

            event_options = EMPLOYER_EDI_EVENTS_ON_SAVE.include?(event) ? {observer_klass: BenefitSponsors::Observers::EdiObserver} : {}
            notify_observers(ModelEvent.new(event, self, event_options))
          rescue StandardError => e
            Rails.logger.info { "Benefit Application REGISTERED_EVENTS_ON_SAVE: #{event} unable to notify observers" }
            raise e if Rails.env.test? # RSpec Expectation Not Met Error is getting rescued here
          end
        end
      end

      def notify_on_create
        if self.is_renewing? && self.benefit_sponsorship.benefit_applications.published.present?
          is_renewal_application_created = true
        end

        REGISTERED_EVENTS_ON_CREATE.each do |event|
          next unless (event_fired = instance_eval("is_" + event.to_s))

          event_options = {}
          notify_observers(ModelEvent.new(event, self, event_options))
        rescue StandardError => e
          Rails.logger.info { "Benefit Application REGISTERED_EVENTS_ON_CREATE: #{event} unable to notify observers" }
          raise e if Rails.env.test? # RSpec Expectation Not Met Error is getting rescued here
        end
      end

      def trigger_model_event(event_name, event_options = {})
        if OTHER_EVENTS.include?(event_name)
          BenefitSponsors::BenefitApplications::BenefitApplication.add_observer(BenefitSponsors::Observers::NoticeObserver.new, [:process_application_events])
          notify_observers(ModelEvent.new(event_name, self, event_options))
        end
      end

      def is_transition_matching?(from: nil, to: nil, event: nil)
        aasm_matcher = lambda {|expected, current|
          expected.blank? || expected == current || (expected.is_a?(Array) && expected.include?(current))
        }

        current_event_name = aasm.current_event.to_s.gsub('!', '').to_sym
        aasm_matcher.call(from, aasm.from_state) && aasm_matcher.call(to, aasm.to_state) && aasm_matcher.call(event, current_event_name)
      end

      def self.included(base)
        base.extend ClassMethods
      end

      module ClassMethods
        def date_change_event(new_date)

          if new_date.day == Settings.aca.shop_market.renewal_application.application_submission_soft_deadline - 2 #2 days before soft dead line i.e 3th of the month
            is_renewal_employer_first_reminder_to_publish_plan_year = true
          elsif new_date.day == Settings.aca.shop_market.renewal_application.application_submission_soft_deadline - 1 #one day before advertised soft deadline i.e 4th of the month
            is_renewal_employer_second_reminder_to_publish_plan_year = true
          elsif new_date.day == Settings.aca.shop_market.renewal_application.publish_due_day_of_month - 2 #2 days prior to the publish due date i.e 8th of the month
            is_renewal_employer_third_reminder_to_publish_plan_year = true
          end

          #initial employers misses binder payment deadline
          scheduler = BenefitSponsors::BenefitApplications::BenefitApplicationSchedular.new
          binder_next_day = scheduler.calculate_open_enrollment_date(false, TimeKeeper.date_of_record.next_month.beginning_of_month)[:binder_payment_due_date].next_day
          if  Settings.site.key == :dc && new_date.day == Settings.aca.shop_market.initial_application.non_binder_paid_notice_day_of_month
            is_initial_employer_no_binder_payment_received = true
          elsif Settings.site.key == :cca && new_date.day == binder_next_day
            is_initial_employer_no_binder_payment_received = true
          end

          if (new_date + 2.days).day == Settings.aca.shop_market.initial_application.advertised_deadline_of_month # 2 days prior to advertised deadline(1st) of month
            is_initial_employer_first_reminder_to_publish_plan_year = true
          elsif (new_date + 1.day).day == Settings.aca.shop_market.initial_application.advertised_deadline_of_month # 1 day prior to advertised deadline(1st) of month
            is_initial_employer_second_reminder_to_publish_plan_year = true
          elsif new_date.day == Settings.aca.shop_market.initial_application.publish_due_day_of_month - 2 # 2 days prior to publish due day(5th) of month
            is_initial_employer_final_reminder_to_publish_plan_year = true
          end

          # triggering the event every day open enrollment end reminder notice to employees
          # This is because there is a possibility for the employers to change the open enrollment end date
          # This also triggers low enrollment notice to employer
          is_open_enrollment_end_reminder_and_low_enrollment = true

          DATE_CHANGE_EVENTS.each do |event|
            next unless (event_fired = instance_eval("is_" + event.to_s))

            event_options = {}
            new.notify_observers(ModelEvent.new(event, self, event_options))
          rescue StandardError => e
            Rails.logger.error { "Benefit Application DATE_CHANGE_EVENTS: #{event} - unable to notify observers" }
            raise e if Rails.env.test? # RSpec Expectation Not Met Error is getting rescued here
          end
        end
      end
    end
  end
end

# rubocop:enable Lint/UselessAssignment
