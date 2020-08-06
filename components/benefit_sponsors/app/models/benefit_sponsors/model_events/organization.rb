# frozen_string_literal: true

# rubocop:disable Lint/UselessAssignment
module BenefitSponsors
  module ModelEvents
    module Organization
      REGISTERED_EVENTS = [
        :welcome_notice_to_employer
      ].freeze

      def notify_on_create
        is_welcome_notice_to_employer = true if self.employer_profile

        REGISTERED_EVENTS.each do |event|
          next unless (event_fired = instance_eval("is_" + event.to_s))

          event_options = {}
          notify_observers(ModelEvent.new(event, self, event_options))
        rescue StandardError => e
          Rails.logger.info { "Organization REGISTERED_EVENTS: #{event} unable to notify observers" }
          raise e if Rails.env.test? # RSpec Expectation Not Met Error is getting rescued here
        end
      end
    end
  end
end

# rubocop:enable Lint/UselessAssignment
