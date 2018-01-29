module Events
  class ResidencyVerificationRequestsController < ::ApplicationController
    include Acapi::Notifiers

    def self.subscription_details
      [ConsumerRole::RESIDENCY_VERIFICATION_REQUEST_EVENT_NAME]
    end

    def call(event_name, e_start, e_end, msg_id, payload)
      individual = payload.stringify_keys["person"]
      event_payload = render_to_string "events/residency/verification_request", :formats => ["xml"], :locals => { :individual => individual }
      event_request_record = EventRequest.new({requested_at: Time.now, body: event_payload})
      individual.consumer_role.local_residency_requests << event_request_record
      individual.consumer_role.add_type_history_element(verification_type: "DC Residency",
                                             action: "Local Hub Request",
                                             modifier: "Enroll App",
                                             update_reason: "Hub request",
                                             event_request_record_id: event_request_record.id)
      notify("acapi.info.events.residency.verification_request", {:body => event_payload, :individual_id => individual.hbx_id, :retry_deadline => (Time.now + 24.hours).to_i})
    end

    def self.subscribe
      ActiveSupport::Notifications.subscribe(*self.subscription_details) do |e_name, e_start, e_end, msg_id, payload|
        self.new.call(e_name, e_start,e_end,msg_id,payload)
      end
    end
  end
end
