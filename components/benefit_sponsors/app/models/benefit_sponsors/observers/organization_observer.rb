module BenefitSponsors
  module Observers
    class OrganizationObserver
      include ::Acapi::Notifiers

      attr_accessor :notifier

      def update(instance, options = {})
        return unless instance.employer_profile.present?

        event_names = Array.new

        BenefitSponsors::Organizations::Organization::FIELD_AND_EVENT_NAMES_MAP.each do |key, event_name|
          event_names << event_name if instance.changed_attributes.include?(key)
        end

        if event_names.any?
          event_names.each do |event_name|
            payload = {
                employer_id: instance.hbx_id,
                event_name: "#{event_name}"
            }
            notify("acapi.info.events.employer.#{event_name}", payload)
          end
        end
      end

      def notifications_send(model_instance, new_model_event)
        if new_model_event.present? &&  new_model_event.is_a?(BenefitSponsors::ModelEvents::ModelEvent)
          organization = new_model_event.klass_instance
          if new_model_event.event_key == :welcome_notice_to_employer
            deliver(recipient: organization.employer_profile, event_object: organization.employer_profile, notice_event: "welcome_notice_to_employer")
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
