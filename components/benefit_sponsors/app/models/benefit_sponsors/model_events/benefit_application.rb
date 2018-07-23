module BenefitSponsors
  module ModelEvents
    module BenefitApplication

      APPLICATION_EXCEPTION_STATES  = [:pending, :assigned, :processing, :reviewing, :information_needed, :appealing].freeze

      REGISTERED_EVENTS = [
        :application_submitted,
        :ineligible_application_submitted,
        :employer_open_enrollment_completed,
        :application_denied,
        :renewal_application_created,
        :renewal_application_autosubmitted,

        # :renewal_enrollment_confirmation,
        # :renewal_application_submitted,
        # :ineligible_renewal_application_submitted,
        # :open_enrollment_began, #not being used
        # :renewal_application_denied,
        # :zero_employees_on_roster,
      ]

      DATA_CHANGE_EVENTS = [
          :renewal_employer_publish_plan_year_reminder_after_soft_dead_line,
          :renewal_employer_open_enrollment_completed,
          :renewal_plan_year_first_reminder_before_soft_dead_line,
          :initial_employer_no_binder_payment_received,
          :renewal_plan_year_publish_dead_line,
          :low_enrollment_notice_for_employer,
          :initial_employer_first_reminder_to_publish_plan_year,
          :initial_employer_second_reminder_to_publish_plan_year,
          :initial_employer_final_reminder_to_publish_plan_year
      ]

      OTHER_EVENTS = [
        :group_advance_termination_confirmation
      ]

      # Events triggered by state changes on individual instances
      def notify_on_save
        return if self.is_conversion?
        if aasm_state_changed?

          if is_transition_matching?(to: :enrollment_closed, from: :enrollment_open, event: :end_open_enrollment)
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

          if is_transition_matching?(to: :terminated, from: :active, event: :terminate_enrollment)
            is_group_advance_termination_confirmation = true
          end

          if is_transition_matching?(to: :approved, from: [:draft, :imported] + BenefitSponsors::BenefitApplications::BenefitApplication::APPLICATION_EXCEPTION_STATES, event: :auto_approve_application)
            is_renewal_application_autosubmitted = true
          end

          # if is_transition_matching?(to: :enrollment_closed, from: :enrollment_open, event: :end_open_enrollment)
          #   is_renewal_enrollment_confirmation = true
          # end

          # if is_transition_matching?(to: :renewing_draft, from: :draft, event: :renew_plan_year)
          #   is_renewal_application_created = true
          # end

          # if is_transition_matching?(to: [:renewing_published, :renewing_enrolling], from: :renewing_draft, event: :publish)
          #   is_renewal_application_submitted = true
          # end

          # if is_transition_matching?(to: :renewing_publish_pending, from: :renewing_draft, event: [:publish, :force_publish])
          #   is_ineligible_renewal_application_submitted = true
          # end

          # if is_transition_matching?(to: :terminated, from: [:active, :suspended], event: :terminate)
          #   is_group_advance_termination_confirmation = true
          # end

          # if is_transition_matching?(to: :published, from: :draft, event: :force_publish)
          #   is_zero_employees_on_roster = true
          # end

          # if is_transition_matching?(to: :renewing_application_ineligible, from: :renewing_enrolling, event: :advance_date)
          #   is_renewal_application_denied = true
          # end

          # TODO -- encapsulated notify_observers to recover from errors raised by any of the observers
          REGISTERED_EVENTS.each do |event|
            begin
              if event_fired = instance_eval("is_" + event.to_s)
                event_options = {}
                notify_observers(ModelEvent.new(event, self, event_options))
              end
            rescue Exception => e
              Rails.logger.info { "Benefit Application REGISTERED_EVENTS: #{event} unable to notify observers" }
            end
          end

        end
      end

      def notify_on_create
        if self.is_renewing? && self.benefit_sponsorship.benefit_applications.published.present?
          is_renewal_application_created = true
        end

        REGISTERED_EVENTS.each do |event|
          begin
            if event_fired = instance_eval("is_" + event.to_s)
              event_options = {}
              notify_observers(ModelEvent.new(event, self, event_options))
            end
          rescue Exception => e
            Rails.logger.info { "Benefit Application REGISTERED_EVENTS: #{event} unable to notify observers" }
          end
        end
      end

      def trigger_model_event(event_name, event_options = {})
        if OTHER_EVENTS.include?(event_name)
          BenefitSponsors::BenefitApplications::BenefitApplication.add_observer(BenefitSponsors::Observers::BenefitApplicationObserver.new, [:notifications_send])
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
          # renewal employer publish plan_year reminder a day after advertised soft deadline i.e 11th of the month
          if new_date.day == Settings.aca.shop_market.renewal_application.application_submission_soft_deadline + 1
            is_renewal_employer_publish_plan_year_reminder_after_soft_dead_line = true
          end

          # renewal_application with un-published plan year, send notice 2 days before soft dead line i.e 8th of the month
          if new_date.day == Settings.aca.shop_market.renewal_application.application_submission_soft_deadline - 2
            is_renewal_plan_year_first_reminder_before_soft_dead_line = true
          end

          # renewal_application with enrolling state, reached open-enrollment end date with minimum participation and non-owner-enrolle i.e 15th of month
          if new_date.day == Settings.aca.shop_market.renewal_application.publish_due_day_of_month
            is_renewal_employer_open_enrollment_completed = true
          end

          #initial employers misses binder payment deadline
          scheduler = BenefitSponsors::BenefitApplications::BenefitApplicationSchedular.new
          binder_next_day = scheduler.calculate_open_enrollment_date(TimeKeeper.date_of_record.next_month.beginning_of_month)[:binder_payment_due_date].next_day
          if new_date == binder_next_day
            is_initial_employer_no_binder_payment_received = true
          end

          # renewal_application with un-published plan year, send notice 2 days prior to the publish due date i.e 13th of the month
          if new_date.day == Settings.aca.shop_market.renewal_application.publish_due_day_of_month - 2
            is_renewal_plan_year_publish_dead_line = true
          end

          if new_date.day == Settings.aca.shop_market.renewal_application.monthly_open_enrollment_end_on - 2
            is_low_enrollment_notice_for_employer = true
          end

          if new_date.day == Settings.aca.shop_market.initial_application.advertised_deadline_of_month - 2 # 2 days prior to advertised deadline of month i.e., 8th of the month
            is_initial_employer_first_reminder_to_publish_plan_year = true
          elsif new_date.day == Settings.aca.shop_market.initial_application.advertised_deadline_of_month - 1 # 1 day prior to advertised deadline of month i.e., 9th of the month
            is_initial_employer_second_reminder_to_publish_plan_year = true
          elsif new_date.day == Settings.aca.shop_market.initial_application.publish_due_day_of_month - 2 # 2 days prior to publish deadline of month i.e., 13th of the month
            is_initial_employer_final_reminder_to_publish_plan_year = true
          end

          DATA_CHANGE_EVENTS.each do |event|
            begin
              if event_fired = instance_eval("is_" + event.to_s)
                event_options = {}
                self.new.notify_observers(ModelEvent.new(event, self, event_options))
              end
            rescue Exception => e
              Rails.logger.error { "Benefit Application DATA_CHANGE_EVENTS: #{event} - unable to notify observers" }
            end
          end
        end
      end

    end
  end
end
