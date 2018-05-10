module ModelEvents
  module CensusEmployee

    REGISTERED_EVENTS = [
      :employee_coverage_passively_waived,
      :employee_coverage_passively_renewed,
      :employee_coverage_passive_renewal_failed
    ]

    def notify_on_save
    end

    def is_transition_matching?(from: nil, to: nil, event: nil)
      aasm_matcher = lambda {|expected, current|
        expected.blank? || expected == current || (expected.is_a?(Array) && expected.include?(current))
      }

      current_event_name = aasm.current_event.to_s.gsub('!', '').to_sym
      aasm_matcher.call(from, aasm.from_state) && aasm_matcher.call(to, aasm.to_state) && aasm_matcher.call(event, current_event_name)
    end

    def trigger_model_event(event_name, event_options = {})
      if REGISTERED_EVENTS.include?(event_name)
        notify_observers(ModelEvent.new(event_name, self, event_options))
      end
    end
  end
end