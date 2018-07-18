module BenefitSponsors
  module Observers
    class BrokerAgencyAccountObserver
      include ::Acapi::Notifiers

      attr_accessor :notifier

      def broker_hired?(account, options={})
        if !account.persisted? && account.valid?
          profile = account.benefit_sponsorship.profile
          notify(
            "acapi.info.events.employer.broker_added",
            {
              employer_id: profile.hbx_id,
              event_name: "broker_added"
            }
          )
        end
      end

      def broker_fired?(account, options={})
        if account.persisted? && account.changed? && account.changed_attributes.include?("is_active")
          profile = account.benefit_sponsorship.profile
          notify(
            "acapi.info.events.employer.broker_terminated",
            {
              employer_id: profile.hbx_id,
              event_name: "broker_terminated"
            }
          )
        end
      end

      def notifications_send(model_instance, new_model_event)
        if new_model_event.present? &&  new_model_event.is_a?(BenefitSponsors::ModelEvents::ModelEvent)
          broker_agency_account = new_model_event.klass_instance

          broker_agency_profile = broker_agency_account.broker_agency_profile
          broker = broker_agency_profile.primary_broker_role
          employer_profile = broker_agency_account.benefit_sponsorship.profile

          if BenefitSponsors::ModelEvents::BrokerAgencyAccount::REGISTERED_EVENTS.include?(new_model_event.event_key)
            if new_model_event.event_key == :broker_hired
              deliver(recipient: broker, event_object: employer_profile, notice_event: "broker_hired_notice_to_broker")
              deliver(recipient: broker_agency_profile, event_object: employer_profile, notice_event: "broker_agency_hired_confirmation")
              deliver(recipient: employer_profile, event_object: employer_profile, notice_event: "broker_hired_confirmation_to_employer")
            end

            if new_model_event.event_key == :broker_fired
              deliver(recipient: broker, event_object: employer_profile, notice_event: "broker_fired_confirmation_to_broker")
              deliver(recipient: broker_agency_profile, event_object: employer_profile, notice_event: "broker_agency_fired_confirmation")
              deliver(recipient: employer_profile, event_object: broker_agency_account, notice_event: "broker_fired_confirmation_to_employer")
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
