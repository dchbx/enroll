# frozen_string_literal: true

# rubocop:disable Lint/UselessAssignment
module BenefitSponsors
  module ModelEvents
    module BenefitSponsorship

      REGISTERED_EVENTS = [
        :initial_employee_plan_selection_confirmation
      ].freeze

      def notify_on_save
        if aasm_state_changed?

          if is_transition_matching?(to: :initial_enrollment_eligible, from: [:initial_enrollment_closed, :initial_enrollment_ineligible, :binder_reversed], event: [:approve_initial_enrollment_eligibility, :credit_binder])
            is_initial_employee_plan_selection_confirmation = true
          end

          REGISTERED_EVENTS.each do |event|
            next unless (event_fired = instance_eval("is_" + event.to_s))

            event_options = {}
            notify_observers(ModelEvent.new(event, self, event_options))
          rescue StandardError => e
            Rails.logger.info { "BenefitSponsorship REGISTERED_EVENTS: #{event} unable to notify observers" }
            raise e if Rails.env.test? # RSpec Expectation Not Met Error is getting rescued here
          end
        end
      end

      def is_transition_matching?(from: nil, to: nil, event: nil)
        aasm_matcher = lambda {|expected, current|
          expected.blank? || expected == current || (expected.is_a?(Array) && expected.include?(current))
        }

        current_event_name = aasm.current_event.to_s.gsub('!', '').to_sym
        aasm_matcher.call(from, aasm.from_state) && aasm_matcher.call(to, aasm.to_state) && aasm_matcher.call(event, current_event_name)
      end
    end
  end
end

# rubocop:enable Lint/UselessAssignment
