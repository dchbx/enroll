module Subscribers
  class IamAccountCreation < ::Acapi::Subscription
    include Acapi::Notifiers

    def self.subscription_details
      ["acapi.info.events.account_management.iam_creation_success"]
    end

    def call(event_name, e_start, e_end, msg_id, payload)
      process_response(payload)
    end

    private
    def process_response(payload)
      begin
        stringed_key_payload = payload.stringify_keys
        stringed_key_body = JSON.parse(stringed_key_payload['body'].gsub('=>', ':')).stringify_keys
        idp_uuid = stringed_key_body['_id']
        user_name = stringed_key_body['userName']
        return_status = stringed_key_payload["return_status"].to_s

        if "201" == return_status.to_s
          user = User.where(oim_id: user_name).first
          user.idp_uuid = idp_uuid
          user.save
          return
        end

      rescue => e
        notify("acapi.error.application.enroll.remote_listener.iam_creation_responses", {
          :body => JSON.dump({
             :error => e.inspect,
             :message => e.message,
             :backtrace => e.backtrace
          })})
      end
    end

  end
end
