module Events
  class IndividualsController < ::ApplicationController
    include Acapi::Amqp::Responder

    def resource(connection, delivery_info, properties, body)
      reply_to = properties.reply_to
      headers = properties.headers || {}
      individual_id = headers.stringify_keys["individual_id"]
      individual = Person.by_hbx_id(individual_id).first
      if !individual.nil?
        begin
          response_payload = render_to_string "created", :formats => ["xml"], :locals => { :individual => individual }
          reply_with(connection, reply_to, "200", response_payload, individual_id)
        rescue Exception => e
          reply_with(
            connection,
            reply_to,
            "500",
            JSON.dump({
              exception: e.inspect,
              backtrace: e.backtrace.inspect
            }),
            individual_id
          )
        end
      else
        reply_with(connection, reply_to, "404", "", individual_id)
      end
    end

    def reply_with(connection, reply_to, return_status, body, individual_id)
      with_response_exchange(connection) do |ex|
        ex.publish(
          body,
          {
            :routing_key => reply_to,
            :headers => {
              :return_status => return_status,
              :individual_id => individual_id
            }
          }
        )
      end
    end
  end
end
