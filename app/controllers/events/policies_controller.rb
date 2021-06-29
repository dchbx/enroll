# frozen_string_literal: true

module Events
  class PoliciesController < ::ApplicationController
    include Acapi::Amqp::Responder

    def resource(connection, _delivery_info, properties, _body)
      reply_to = properties.reply_to
      headers = properties.headers || {}
      policy_id = headers.stringify_keys["policy_id"]
      policy = HbxEnrollment.by_hbx_id(policy_id).first
      if policy.nil?
        reply_with(connection, reply_to, policy_id, "404", "")
      else
        begin
#          raise "This policy has no subscriber." if policy.subscriber.blank?
          response_payload = render_to_string "events/enrollment_event", :formats => ["xml"], :locals => { :hbx_enrollment => policy }
          reply_with(connection, reply_to, policy_id, "200", response_payload, policy.eligibility_event_kind)
        rescue Exception => e
          reply_with(
            connection,
            reply_to,
            policy_id,
            "500",
            JSON.dump({
                        exception: e.inspect,
                        backtrace: e.backtrace.inspect
                      })
          )
        end
      end
    end

    def reply_with(connection, reply_to, policy_id, return_status, body, eligibility_event_kind = nil)
      headers = {
        :return_status => return_status,
        :policy_id => policy_id
      }
      headers[:eligibility_event_kind] = eligibility_event_kind unless eligibility_event_kind.blank?
      with_response_exchange(connection) do |ex|
        ex.publish(
          body,
          {
            :routing_key => reply_to,
            :headers => headers
          }
        )
      end
    end
  end
end
