module BenefitSponsors
  module ModelEvents
    module Organization

      REGISTERED_EVENTS = [
        :welcome_notice_to_employer
      ]

      def notify_on_create

        if self.employer_profile
          is_welcome_notice_to_employer = true
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
  end
end