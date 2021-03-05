# frozen_string_literal: true

module BenefitSponsors
  module Observers
    class EdiObserver
      include ::Acapi::Notifiers

      attr_accessor :notifier

      def initialize
        @notifier = BenefitSponsors::Services::EdiService.new
      end

      def deliver(recipient:, event_object:, event_name:, edi_params: {})
        notifier.deliver(recipient: recipient, event_object: event_object, event_name: event_name, edi_params: edi_params)
      end

      def process_application_edi_events(_model_instance, model_event)
        raise ArgumentError, "expected BenefitSponsors::ModelEvents::ModelEvent" unless model_event.present? && model_event.is_a?(BenefitSponsors::ModelEvents::ModelEvent)

        method_name = "trigger_#{model_event.event_key}_event"
        raise StandardError, "unable to find method name: #{method_name}" unless respond_to?(method_name)

        __send__(method_name, model_event)
      end

      def trigger_benefit_coverage_period_terminated_nonpayment_event(model_event)
        employer_profile = model_event.klass_instance.employer_profile
        deliver(recipient: employer_profile, event_object: model_event.klass_instance, event_name: BenefitApplications::BenefitApplication::NON_PAYMENT_TERMINATED_PLAN_YEAR_EVENT_TAG)
      end

      def trigger_benefit_coverage_period_terminated_voluntary_event(model_event)
        employer_profile = model_event.klass_instance.employer_profile
        deliver(recipient: employer_profile, event_object: model_event.klass_instance, event_name: BenefitApplications::BenefitApplication::VOLUNTARY_TERMINATED_PLAN_YEAR_EVENT_TAG)
      end

      def trigger_benefit_coverage_renewal_carrier_dropped_event(model_event)
        employer_profile = model_event.klass_instance.employer_profile
        deliver(recipient: employer_profile, event_object: model_event.klass_instance, event_name: BenefitApplications::BenefitApplication::INITIAL_OR_RENEWAL_PLAN_YEAR_DROP_EVENT_TAG, edi_params: { plan_year_id: model_event.klass_instance.id.to_s })
      end

      def trigger_benefit_coverage_period_reinstated_event(model_event)
        employer_profile = model_event.klass_instance.employer_profile
        deliver(recipient: employer_profile, event_object: model_event.klass_instance, event_name: BenefitApplications::BenefitApplication::REINSTATED_PLAN_YEAR_EVENT_TAG)
      end
    end
  end
end
