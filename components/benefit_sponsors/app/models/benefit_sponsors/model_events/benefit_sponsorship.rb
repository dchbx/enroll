module BenefitSponsors
  module ModelEvents
    module BenefitSponsorship

      REGISTERED_EVENTS = [
        :initial_employee_plan_selection_confirmation
      ]

      def notify_on_save
        if aasm_state_changed?

          if is_transition_matching?(to: :initial_enrollment_eligible, from: [:initial_enrollment_closed, :initial_enrollment_ineligible, :binder_reversed], event: [:approve_initial_enrollment_eligibility, :credit_binder])
            is_initial_employee_plan_selection_confirmation = true
          end

          REGISTERED_EVENTS.each do |event|
            if event_fired = instance_eval("is_" + event.to_s)
              # event_name = ("on_" + event.to_s).to_sym
              event_options = {} # instance_eval(event.to_s + "_options") || {}
              notify_observers(ModelEvent.new(event, self, event_options))
            end
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