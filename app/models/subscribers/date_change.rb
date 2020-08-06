# frozen_string_literal: true

module Subscribers
  class DateChange < ::Acapi::Subscription
    def self.subscription_details
      ["acapi.info.events.calendar.date_change"]
    end

    def call(_event_name, _e_start, _e_end, _msg_id, payload)
      stringed_key_payload = payload.stringify_keys
      current_date_string = stringed_key_payload["current_date"]
      new_date = Date.parse(current_date_string, "%Y-%m-%d")
      ::TimeKeeper.set_date_of_record(new_date)
    end
  end
end
