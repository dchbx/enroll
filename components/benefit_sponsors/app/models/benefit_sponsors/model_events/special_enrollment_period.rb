module BenefitSponsors
  module ModelEvents
    module SpecialEnrollmentPeriod

      REGISTERED_EVENTS = [
        :employee_sep_request_accepted
      ]

      def notify_on_save
        if self._id_changed?
          is_employee_sep_request_accepted = true
        end

        REGISTERED_EVENTS.each do |event|
          if event_fired = instance_eval("is_" + event.to_s)
            event_options = {}
            notify_observers(ModelEvent.new(event, self, event_options))
          end
        end
      end
    end
  end
end