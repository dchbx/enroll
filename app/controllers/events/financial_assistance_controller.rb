module Events
  class FinancialAssistanceController < ::ApplicationController
    include Acapi::Amqp::Responder

    def resource(connection, delivery_info, properties, body)
      reply_to = properties.reply_to
      headers = properties.headers || {}
      family_id = headers.stringify_keys["family_id"]
      family = Family.find(family_id)
      unless family.nil?
        family.applications.where(aasm_state: "submitted").each do |application|
          begin
            response_payload = render_to_string "events/financial_assistance_application", :formats => ["xml"], :locals => { :financial_assistance_application => application }
            reply_with(connection, reply_to, family_id, "200", response_payload)
          rescue Exception=>e
            reply_with(
              connection,
              reply_to,
              family_id,
              "500",
              JSON.dump({
                exception: e.inspect,
                backtrace: e.backtrace.inspect
              })
            )
          end
        end
      end
    end

    def reply_with(connection, reply_to, family_id, return_status, body)
      headers = { 
              :return_status => return_status,
              :family_id => family_id
      }
      with_response_exchange(connection) do |ex|
        ex.publish(body,{:routing_key => reply_to, :headers => headers})
      end
    end
  end
end