module Events
  class BrokersController < ::ApplicationController
    include Acapi::Amqp::Responder

    def resource(connection, delivery_info, properties, body)
      reply_to = properties.reply_to
      headers = properties.headers || {}
      broker_id = headers.stringify_keys["broker_id"]
      individual = Person.by_broker_role_npn(broker_id).first
      if !individual.nil?
        response_payload = render_to_string "events/brokers/created", :formats => ["xml"], :locals => { :individual => individual }
        with_response_exchange(connection) do |ex|
          ex.publish(
            response_payload,
            {
              :routing_key => reply_to,
              :headers => {
                :return_status => "200",
                :broker_id => broker_id
              }
            }
          )
        end
      else
        with_response_exchange(connection) do |ex|
          ex.publish(
            "",
            {
              :routing_key => reply_to,
              :headers => {
                :return_status => "404",
                :broker_id => broker_id
              }
            }
          )
        end
      end
    end
  end
end
