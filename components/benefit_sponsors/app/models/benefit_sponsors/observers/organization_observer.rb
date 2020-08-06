# frozen_string_literal: true

module BenefitSponsors
  module Observers
    class OrganizationObserver
      include ::Acapi::Notifiers

      attr_accessor :notifier

      def update(instance, _options = {})
        return unless instance.employer_profile.present?

        event_names = []

        BenefitSponsors::Organizations::Organization::FIELD_AND_EVENT_NAMES_MAP.each do |key, event_name|
          event_names << event_name if instance.changed_attributes.include?(key)
        end

        if event_names.any?
          event_names.each do |event_name|
            payload = {
              employer_id: instance.hbx_id,
              event_name: event_name.to_s
            }
            notify("acapi.info.events.employer.#{event_name}", payload)
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
