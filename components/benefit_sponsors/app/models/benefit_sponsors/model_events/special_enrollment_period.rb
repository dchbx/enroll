# frozen_string_literal: true

# rubocop:disable Lint/UselessAssignment
module BenefitSponsors
  module ModelEvents
    module SpecialEnrollmentPeriod

      REGISTERED_EVENTS = [
        :employee_sep_request_accepted
      ].freeze

      def notify_on_save
        if self._id_changed?
          is_employee_sep_request_accepted = true
        end

        REGISTERED_EVENTS.each do |event|
          next unless (event_fired = instance_eval("is_" + event.to_s))

          event_options = {}
          notify_observers(ModelEvent.new(event, self, event_options))
        rescue StandardError => e
          Rails.logger.info { "SpecialEnrollmentPeriod REGISTERED_EVENTS: #{event} unable to notify observers" }
          raise e if Rails.env.test? # RSpec Expectation Not Met Error is getting rescued here
        end
      end
    end
  end
end

# rubocop:enable Lint/UselessAssignment
