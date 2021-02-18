# frozen_string_literal: true

module BenefitSponsors
  module Services
    class BenefitApplicationActionService

      attr_reader :benefit_application, :args, :benefit_sponsorship

      def initialize(benefit_application, args)
        @benefit_application = benefit_application
        @benefit_sponsorship = benefit_application.benefit_sponsorship
        @args = args
      end

      def terminate_application
        failed_results = {}
        # Cancels renewal application
        if benefit_sponsorship.renewal_benefit_application
          service = initialize_service(benefit_sponsorship.renewal_benefit_application)
          result, ba, errors = service.cancel
          map_errors_for(errors, onto: failed_results) if errors.present?
        end

        # Cancel reinstated application
        reinstated_app = benefit_sponsorship.benefit_applications.detect{|app| app.active? && app.reinstated_id == benefit_application.id}
        if reinstated_app && reinstated_app.start_on != args[:end_on].to_date.next_day
          service = initialize_service(reinstated_app)
          _result, _ba, errors = service.cancel
          map_errors_for(errors, onto: failed_results) if errors.present?
        end

        # Terminates current application
        service = initialize_service(benefit_application)
        result, ba, errors =
          if args[:end_on] >= TimeKeeper.date_of_record
            service.schedule_termination(args[:end_on], TimeKeeper.date_of_record, args[:termination_kind], args[:termination_reason], args[:transmit_to_carrier])
          else
            service.terminate(args[:end_on], TimeKeeper.date_of_record, args[:termination_kind], args[:termination_reason], args[:transmit_to_carrier])
          end
        map_errors_for(errors, onto: failed_results) if errors.present?
        [result, ba, failed_results]
      rescue StandardError => e
        Rails.logger.error { "Error terminating #{benefit_sponsorship.organization.legal_name}'s benefit application due to #{e.backtrace}" }
      end

      def cancel_application
        service = initialize_service(benefit_application)
        result, ba, errors = service.cancel(args[:transmit_to_carrier])
        [result, ba, errors]
      rescue StandardError => e
        Rails.logger.error { "Error canceling #{benefit_sponsorship.organization.legal_name}'s benefit application due to #{e.backtrace}" }
      end

      def initialize_service(application)
        BenefitSponsors::BenefitApplications::BenefitApplicationEnrollmentService.new(application)
      end

      def map_errors_for(errors, onto:)
        errors.each do |k, v|
          onto[k] = v
        end
      end
    end
  end
end
