# frozen_string_literal: true

module ModelEvents
  module Document
    REGISTERED_EVENTS = [
      :initial_employer_invoice_available
    ].freeze

    def notify_on_save
      is_initial_employer_invoice_available = true if subject == 'initial_invoice' && identifier.present?

      REGISTERED_EVENTS.each do |event|
        next unless event_fired = instance_eval("is_" + event.to_s)
        # event_name = ("on_" + event.to_s).to_sym
        event_options = {} # instance_eval(event.to_s + "_options") || {}
        notify_observers(ModelEvent.new(event, self, event_options))
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