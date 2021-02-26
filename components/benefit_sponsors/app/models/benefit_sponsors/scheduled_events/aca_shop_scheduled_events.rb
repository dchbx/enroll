module BenefitSponsors
  module ScheduledEvents
    class AcaShopScheduledEvents

      include ::Acapi::Notifiers
      include Config::AcaModelConcern

      attr_reader :new_date

      def self.advance_day(new_date)
        self.new(new_date)
      end

      def initialize(new_date)
        @new_date = new_date
        initialize_logger
        shop_daily_events
        auto_submit_renewal_applications
        # process_applications_missing_binder_payment #refs 39124 - Had to comment out as we got rid of states on BS.
        auto_cancel_ineligible_applications
        auto_transmit_monthly_benefit_sponsors
        close_enrollment_quiet_period
      end

      def shop_daily_events
        process_events_for { open_enrollment_begin }
        process_events_for { open_enrollment_end }
        process_events_for { benefit_begin }
        process_events_for { benefit_end }
        process_events_for { benefit_termination }
        process_events_for { benefit_termination_pending }
        process_events_for { benefit_renewal }
      end

      def open_enrollment_begin
        benefit_sponsorships = BenefitSponsorships::BenefitSponsorship.may_begin_open_enrollment?(new_date)
        execute_sponsor_event(benefit_sponsorships, :begin_open_enrollment)
      end

      def open_enrollment_end
        benefit_sponsorships = BenefitSponsorships::BenefitSponsorship.may_end_open_enrollment?(new_date)
        execute_sponsor_event(benefit_sponsorships, :end_open_enrollment)
      end

      def benefit_begin
        benefit_sponsorships = BenefitSponsorships::BenefitSponsorship.may_begin_benefit_coverage?(new_date)
        execute_sponsor_event(benefit_sponsorships, :begin_sponsor_benefit)
      end

      def benefit_end
        benefit_sponsorships = BenefitSponsorships::BenefitSponsorship.may_end_benefit_coverage?(new_date)
        execute_sponsor_event(benefit_sponsorships, :end_sponsor_benefit)
      end

      def benefit_termination
        benefit_sponsorships = BenefitSponsorships::BenefitSponsorship.may_terminate_benefit_coverage?(new_date)
        execute_sponsor_event(benefit_sponsorships, :terminate_sponsor_benefit)
      end

      def benefit_termination_pending
        benefit_sponsorships = BenefitSponsorships::BenefitSponsorship.may_terminate_pending_benefit_coverage?(new_date)
        execute_sponsor_event(benefit_sponsorships, :terminate_pending_sponsor_benefit)
      end

      def benefit_renewal
        months_prior_to_effective = Settings.aca.shop_market.renewal_application.earliest_start_prior_to_effective_on.months.abs
        renewal_offset_days = Settings.aca.shop_market.renewal_application.earliest_start_prior_to_effective_on.day_of_month.days
        renewal_application_begin = (new_date + months_prior_to_effective.months - renewal_offset_days)

        if renewal_application_begin.mday == 1
          benefit_sponsorships = BenefitSponsors::BenefitSponsorships::BenefitSponsorship.may_renew_application?(renewal_application_begin.prev_day)
          execute_sponsor_event(benefit_sponsorships, :renew_sponsor_benefit)
        end
      end

      def process_applications_missing_binder_payment
        application_effective_date = new_date.next_month.beginning_of_month
        scheduler = BenefitSponsors::BenefitApplications::BenefitApplicationSchedular.new
        binder_next_day = scheduler.calculate_open_enrollment_date(false, application_effective_date)[:binder_payment_due_date].next_day

        if new_date == binder_next_day
          benefit_sponsorships = BenefitSponsorships::BenefitSponsorship.may_transition_as_initial_ineligible?(application_effective_date)
          execute_sponsor_event(benefit_sponsorships, :mark_initial_ineligible)
        end
      end

      def auto_cancel_ineligible_applications
        if new_date.mday == 1
          benefit_sponsorships = BenefitSponsorships::BenefitSponsorship.may_cancel_ineligible_application?(new_date)
          execute_sponsor_event(benefit_sponsorships, :auto_cancel_ineligible)
        end
      end

      def auto_submit_renewal_applications
        if new_date.day == Settings.aca.shop_market.renewal_application.force_publish_day_of_month
          effective_on = new_date.next_month.beginning_of_month
          benefit_sponsorships = BenefitSponsorships::BenefitSponsorship.may_auto_submit_application?(effective_on)
          execute_sponsor_event(benefit_sponsorships, :auto_submit_application)
        end
      end

      def auto_transmit_monthly_benefit_sponsors
        if aca_shop_market_transmit_scheduled_employers
          if (new_date.prev_day.mday + 1) >= aca_shop_market_employer_transmission_day_of_month
            transmit_scheduled_benefit_sponsors(new_date)
          end
        end
      end

      def transmit_scheduled_benefit_sponsors(new_date, feins=[])
        start_on = new_date.prev_day.next_month.beginning_of_month
        transition_at = (new_date.prev_day.mday + 1) == aca_shop_market_employer_transmission_day_of_month ? nil : new_date.prev_day
        benefit_sponsors = BenefitSponsors::BenefitSponsorships::BenefitSponsorship
        benefit_sponsors = benefit_sponsors.find_by_feins(feins) if feins.any?

        renewal_benefit_sponsorships = benefit_sponsors.may_transmit_renewal_enrollment?(start_on, transition_at)
        execute_sponsor_event(renewal_benefit_sponsorships, :transmit_renewal_eligible_event)
        execute_sponsor_event(renewal_benefit_sponsorships, :transmit_renewal_carrier_drop_event) if aca_shop_market_transmit_employer_carrier_drop_events

        initial_benefit_sponsorships = benefit_sponsors.may_transmit_initial_enrollment?(start_on, transition_at)
        execute_sponsor_event(initial_benefit_sponsorships, :transmit_initial_eligible_event)
      end

      def close_enrollment_quiet_period
        if new_date.prev_day.mday == Settings.aca.shop_market.initial_application.quiet_period.mday
          effective_on = (new_date.prev_day.beginning_of_month - Settings.aca.shop_market.initial_application.quiet_period.month_offset.months).to_s(:db)
          notify("acapi.info.events.employer.initial_employer_quiet_period_ended", {:effective_on => effective_on})
        end
      end

      private

      def execute_sponsor_event(benefit_sponsorships, event)
        notify_logger("Event: #{event}. Process started at #{Time.now.in_time_zone('Eastern Time (US & Canada)').strftime('%m-%d-%Y %H:%M:%S')}")
        BenefitSponsors::BenefitSponsorships::BenefitSponsorshipDirector.new(new_date).process(benefit_sponsorships, event)
        notify_logger("Event: #{event}. Process ended at #{Time.now.in_time_zone('Eastern Time (US & Canada)').strftime('%m-%d-%Y %H:%M:%S')}")
      end

      def process_events_for(&block)
        begin
          block.call
        rescue Exception => e
          @logger.error e.message
          @logger.error e.backtrace.join("\n")
        end
      end

      def initialize_logger
        @logger = Logger.new("#{Rails.root}/log/aca_shop_scheduled_events_#{TimeKeeper.date_of_record.strftime('%Y_%m_%d')}.log") unless defined? @logger
      end

      def notify_logger(message)
        @logger.info(message)
        log(message) unless Rails.env.test?
      end
    end
  end
end
