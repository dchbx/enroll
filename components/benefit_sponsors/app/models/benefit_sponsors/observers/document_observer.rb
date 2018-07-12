module BenefitSponsors
  module Observers
    class DocumentObserver
      include ::Acapi::Notifiers

      attr_accessor :notifier

      def notifications_send(model_instance, new_model_event)
        if new_model_event.present? && new_model_event.is_a?(BenefitSponsors::ModelEvents::ModelEvent)
          if BenefitSponsors::ModelEvents::Document::REGISTERED_EVENTS.include?(new_model_event.event_key)
            document = new_model_event.klass_instance
            employer_profile = document.documentable
            eligible_states = BenefitSponsors::BenefitApplications::BenefitApplication::PUBLISHED_STATES
            benefit_application = employer_profile.latest_benefit_sponsorship.benefit_applications.where(:aasm_state.in => eligible_states).first

            if (new_model_event.event_key == :initial_employer_invoice_available) && benefit_application
              deliver(recipient: employer_profile, event_object: benefit_application, notice_event: "initial_employer_invoice_available")
            end

            if (new_model_event.event_key == :employer_invoice_available) && benefit_application
              deliver(recipient: employer_profile, event_object: benefit_application, notice_event: "employer_invoice_available")
            end
          end
        end
      end

      private

      def initialize
        @notifier = BenefitSponsors::Services::NoticeService.new
      end

      def deliver(recipient:, event_object:, notice_event:, notice_params: {})
        notifier.deliver(recipient: recipient, event_object: event_object, notice_event: notice_event, notice_params: notice_params)
      end
    end
  end
end