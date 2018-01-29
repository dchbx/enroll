module Subscribers
  class LocalResidency < ::Acapi::Subscription
    include Acapi::Notifiers
    def self.subscription_details
      ["acapi.info.events.residency.verification_response"]
    end

    def call(event_name, e_start, e_end, msg_id, payload)
      process_response(payload)
    end

    private
    def process_response(payload)
      begin
        stringed_key_payload = payload.stringify_keys
        xml = stringed_key_payload['body']
        person_hbx_id = stringed_key_payload['individual_id']
        return_status = stringed_key_payload["return_status"].to_s

        person = find_person(person_hbx_id)
        return if person.nil? || person.consumer_role.nil?
        consumer_role = person.consumer_role
        event_response_record = EventResponse.new({received_at: Time.now, body: xml})
        consumer_role.local_residency_responses << event_response_record
        consumer_role.add_type_history_element(verification_type: "DC Residency",
                                               action: "Local Hub response",
                                               modifier: "external Hub",
                                               update_reason: "Hub response",
                                               event_response_record_id: event_response_record.id)

        if "503" == return_status.to_s
          consumer_role.deny_residency!
          consumer_role.save
          return
        end

        xml_hash = xml_to_hash(xml)

        update_consumer_role(consumer_role, xml_hash)
      rescue => e
        notify("acapi.error.application.enroll.remote_listener.local_residency_responses", {
          :body => JSON.dump({
            :error => e.inspect,
            :message => e.message,
            :backtrace => e.backtrace
          })})
      end
    end

    def update_consumer_role(consumer_role, xml_hash)
      if xml_hash[:residency_verification_response].eql? 'ADDRESS_NOT_IN_AREA'
        consumer_role.fail_residency!
      else
        consumer_role.pass_residency!
      end

      consumer_role.save
    end

    def xml_to_hash(xml)
      Parsers::Xml::Cv::ResidencyVerificationResponse.parse(xml).to_hash
    end

    def find_person(person_hbx_id)
      Person.where(hbx_id:person_hbx_id).first
    end
  end
end
