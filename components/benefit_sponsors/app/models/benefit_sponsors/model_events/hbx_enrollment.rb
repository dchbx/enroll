# frozen_string_literal: true

# rubocop:disable Lint/UselessAssignment
module BenefitSponsors
  module ModelEvents
    module HbxEnrollment

      REGISTERED_EVENTS = [
        :application_coverage_selected,
        # :employee_waiver_confirmation,
        :employee_coverage_termination
      ].freeze

      def notify_on_save

        if aasm_state_changed?

          if is_transition_matching?(to: [:coverage_selected, :renewing_coverage_selected],  from: [:shopping, :auto_renewing], event: :select_coverage)
            is_application_coverage_selected = true
          end

          # if is_transition_matching?(to: :inactive, from: [:shopping, :coverage_selected, :auto_renewing, :renewing_coverage_selected], event: :waive_coverage)
          #   is_employee_waiver_confirmation = true
          # end

          if is_transition_matching?(to: [:coverage_terminated, :coverage_termination_pending], from: [:coverage_selected, :coverage_enrolled, :auto_renewing,
                           :renewing_coverage_selected,:auto_renewing_contingent, :renewing_contingent_selected, :renewing_contingent_transmitted_to_carrier,
                           :renewing_contingent_enrolled, :enrolled_contingent, :unverified], event: [:terminate_coverage, :schedule_coverage_termination])
            is_employee_coverage_termination = true
          end

          # TODO -- encapsulated notify_observers to recover from errors raised by any of the observers
          REGISTERED_EVENTS.each do |event|
            next unless (event_fired = instance_eval("is_" + event.to_s))

            event_options = {}
            notify_observers(ModelEvent.new(event, self, event_options))
          rescue StandardError => e
            Rails.logger.info { "HbxEnrollment REGISTERED_EVENTS: #{event} unable to notify observers" }
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