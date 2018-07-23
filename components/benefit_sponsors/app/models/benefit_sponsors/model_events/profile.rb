module BenefitSponsors
  module ModelEvents
    module Profile

      REGISTERED_EVENTS = []

      #TODO: The trigger for this notice is in the controller and it has to be eventually moved to observer pattern.
      #TODO: This is the temporary fix until then.
      OTHER_EVENTS = [
        :generate_initial_employer_invoice
      ]

      def trigger_model_event(event_name, event_options = {})
        if OTHER_EVENTS.include?(event_name)
          BenefitSponsors::Organizations::AcaShopCcaEmployerProfile.add_observer(BenefitSponsors::Observers::EmployerProfileObserver.new, [:update, :notifications_send])
          notify_observers(ModelEvent.new(event_name, self, event_options))
        end
      end

      def notify_on_save
        if aasm_state_changed?

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