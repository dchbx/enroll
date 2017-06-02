module Subscribers
  class NfpEnrollmentData < ::Acapi::Subscription
    include Acapi::Notifiers

    def self.subscription_details
      ["acapi.info.events.employer.nfp_enrollment_data_response"]
    end

    def call(event_name, e_start, e_end, msg_id, payload)
      process_response(payload)
    end

    private
    def process_response(payload)
      begin
        stringed_key_payload = payload.stringify_keys
        xml = stringed_key_payload['body']

        #TODO change response handler
        if "503" == return_status.to_s

          return
        end

        xml_hash = xml_to_hash(xml)

      rescue => e
        notify("acapi.error.application.enroll.remote_listener.nfp_enrollment_data_responses", {
          :body => JSON.dump({
             :error => e.inspect,
             :message => e.message,
             :backtrace => e.backtrace
          })})
      end
    end

  end
end
