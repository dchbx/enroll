# frozen_string_literal: true

# rubocop:disable Lint/UselessAssignment
module BenefitSponsors
  module ModelEvents
    module BrokerAgencyAccount

      REGISTERED_EVENTS = [
        :broker_hired,
        :broker_fired
      ].freeze

      def notify_on_save
        if is_active_changed? && (!is_active.nil?)
          if is_active
            is_broker_hired = true
          end

          if !is_active
            is_broker_fired = true
          end
        end

        REGISTERED_EVENTS.each do |event|
          next unless (event_fired = instance_eval("is_" + event.to_s))

          event_options = {}
          notify_observers(ModelEvent.new(event, self, event_options))
        rescue StandardError => e
          Rails.logger.info { "BrokerAgencyAccount REGISTERED_EVENTS: #{event} unable to notify observers" }
          raise e if Rails.env.test? # RSpec Expectation Not Met Error is getting rescued here
        end
      end
    end
  end
end

# rubocop:enable Lint/UselessAssignment
