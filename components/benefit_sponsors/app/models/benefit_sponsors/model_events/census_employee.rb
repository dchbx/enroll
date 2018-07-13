module BenefitSponsors
  module ModelEvents
    module CensusEmployee

      REGISTERED_EVENTS = [
        :employee_notice_for_employee_terminated_from_roster
      ]

      OTHER_EVENTS = [
        :employee_coverage_passively_waived,
        :employee_coverage_passively_renewed,
        :employee_coverage_passive_renewal_failed,
      ]

      def notify_on_save
        if is_transition_matching?(to: [:employment_terminated, :employee_termination_pending], from: [:eligible, :employee_role_linked, :newly_designated_eligible, :newly_designated_linked], event: [:terminate_employee_role, :schedule_employee_termination])
          is_employee_notice_for_employee_terminated_from_roster = true
        end

        REGISTERED_EVENTS.each do |event|
          if event_fired = instance_eval("is_" + event.to_s)
            # event_name = ("on_" + event.to_s).to_sym
            event_options = {} # instance_eval(event.to_s + "_options") || {}
            notify_observers(ModelEvent.new(event, self, event_options))
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

      def trigger_model_event(event_name, event_options = {})
        if OTHER_EVENTS.include?(event_name)
          notify_observers(ModelEvent.new(event_name, self, event_options))
        end
      end
    end
  end
end