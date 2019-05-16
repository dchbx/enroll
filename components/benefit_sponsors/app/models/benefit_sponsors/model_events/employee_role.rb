# frozen_string_literal: true

# rubocop:disable Lint/UselessAssignment
module BenefitSponsors
  module ModelEvents
    module EmployeeRole

      REGISTERED_EVENTS = [
        :employee_matches_employer_roster
      ].freeze

      def notify_on_create

        (is_employee_matches_employer_roster = true) if present?

        REGISTERED_EVENTS.each do |event|
          next unless (event_fired = instance_eval("is_" + event.to_s))

          event_options = {}
          notify_observers(ModelEvent.new(event, self, event_options))
        rescue StandardError => e
          Rails.logger.info { "EmployeeRole REGISTERED_EVENTS: #{event} unable to notify observers"}
          raise e if Rails.env.test? # RSpec Expectation Not Met Error is getting rescued here
        end
      end
    end
  end
end

# rubocop:enable Lint/UselessAssignment
