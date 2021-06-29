# frozen_string_literal: true

module Events
  class SsaVerificationRequestsController < ::ApplicationController
    include Acapi::Notifiers

    def self.subscription_details
      [LawfulPresenceDetermination::SSA_VERIFICATION_REQUEST_EVENT_NAME]
    end

    def call(_event_name, _e_start, _e_end, _msg_id, payload)
      individual = payload.stringify_keys["person"]
      event_payload = render_to_string "events/lawful_presence/ssa_verification_request", :formats => ["xml"], :locals => { :individual => individual }
      event_request_record = EventRequest.new({requested_at: Time.now, body: event_payload})
      individual.consumer_role.lawful_presence_determination.ssa_requests << event_request_record
      types_to_update = individual.verification_types.active.reject{|type| [VerificationType::LOCATION_RESIDENCY, "American Indian Status", "Immigration status"].include? type.type_name }
      types_to_update.each do |type|
        type.add_type_history_element(action: "SSA Hub Request",
                                      modifier: "Enroll App",
                                      update_reason: "Hub request",
                                      event_request_record_id: event_request_record.id)
      end
      notify("acapi.info.events.lawful_presence.ssa_verification_request", {
               :body => event_payload,
               :individual_id => individual.hbx_id,
               :retry_deadline => (Time.now + 24.hours).to_i
             })
    end

    def self.subscribe
      ActiveSupport::Notifications.subscribe(*self.subscription_details) do |e_name, e_start, e_end, msg_id, payload|
        self.new.call(e_name, e_start,e_end,msg_id,payload)
      end
    end
  end
end
