module ModelEvents
  module FaaApplication
    REGISTERED_EVENTS = [
      :ineligibility_notice,
      :eligibility_notice
    ].freeze

    def notify_on_save
      return unless aasm_state_changed?

      if aasm_state_was == "submitted" && aasm_state == "determined"
        if is_family_totally_ineligibile
          is_ineligibility_notice = true
        else
          is_eligibility_notice = true
        end
      end

      REGISTERED_EVENTS.each do |event|
        next unless instance_eval('is_' + event.to_s)

        event_options = {}
        notify_observers(ModelEvent.new(event, self, event_options))
      end
    end
  end
end
