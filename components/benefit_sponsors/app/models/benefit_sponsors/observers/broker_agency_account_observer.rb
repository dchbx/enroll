# frozen_string_literal: true

module BenefitSponsors
  module Observers
    class BrokerAgencyAccountObserver
      include ::Acapi::Notifiers

      attr_accessor :notifier

      def broker_hired?(account, _options = {})
        if !account.persisted? && account.valid? && account.benefit_sponsorship?
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

      def broker_fired?(account, _options = {})
        return unless account.persisted? && account.changed? && account.changed_attributes.include?("end_on") && account.benefit_sponsorship.present?
        profile = account.benefit_sponsorship.profile
        notify(
          "acapi.info.events.employer.broker_terminated",
          {
            employer_id: profile.hbx_id,
            event_name: "broker_terminated"
          }
        )
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
