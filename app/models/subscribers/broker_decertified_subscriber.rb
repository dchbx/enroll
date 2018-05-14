module Subscribers
  class BrokerDecertifiedSubscriber < ::Acapi::Subscription
    include Acapi::Notifiers
    def self.subscription_details
      ["acapi.info.events.broker_role.decertified"]
    end

    def call(event_name, e_start, e_end, msg_id, payload)
      employer_broker_role_id = nil
      begin
        stringed_key_payload = payload.stringify_keys
        broker_role_id = stringed_key_payload["broker_role_id"]
        broker_role = BrokerRole.find(broker_role_id)
        if broker_role.nil?
          notify("acapi.error.events.broker_role.broker_decertification.broker_not_found", {
            :broker_role_id => broker_role_id,
            :return_status => "404"
          })
        else
          broker_role.remove_broker_assignments
        end
      rescue Exception => e
        error_payload = JSON.dump({
          :error => e.inspect,
          :message => e.message,
          :backtrace => e.backtrace
        })
        notify("acapi.error.events.broker_role.broker_decertification.unknown_error", {
          :broker_role_id => broker_role_id,
          :return_status => "500",
          :body => error_payload
        })
      end
    end
  end
end
