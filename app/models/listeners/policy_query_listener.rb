module Listeners
  class PolicyQueryListener < ::Acapi::Amqp::Client
    include ::AmqpClientHelpers

    ProcessingFailure = Struct.new(:response_code, :response_body)

    def self.queue_name
      config = Rails.application.config.acapi
      "#{config.hbx_id}.#{config.environment_name}.q.#{config.app_id}.policy_query_listener"
    end

    def extract_criteria(headers)
      criteria_name = headers["query_criteria_name"]
      case criteria_name
      when "all_outstanding_shop"
        lambda do |exclusions|
          all_outstanding_shop(exclusions)          
        end
      else
        throw :processing_failure, ProcessingFailure.new("422", "Invalid query name specified.")
      end 
    end

    def extract_exclusions(headers, payload)
      are_exclusions_compressed = headers["deflated_payload"]
      is_deflated = (are_exclusions_compressed == "true")
      exclusion_list_string = ::PayloadInflater.inflate(is_deflated, payload)
      JSON.load(exclusion_list_string)
    end

    def on_message(delivery_info, properties, payload)
      headers = properties.headers || {}
      reply_to = properties.reply_to
      sc = ShortCircuit.on(:processing_failure) do |issue|
        with_response_exchange(connection) do |ex|
          ex.publish(
            issue.response_body,
            {
              :reply_to => reply_to,
              :headers => {
                :return_status => issue.response_code
              }
            }
          )
        end
        channel.acknowledge(delivery_info.delivery_tag, false)
      end
      sc.and_then do |args|
        criteria = extract_criteria(headers)
        exclusions = extract_exclusions(headers, payload)
        policy_ids = criteria.call(exclusions)
        response_payload = JSON.dump(policy_ids)
        with_response_exchange(connection) do |ex|
          ex.publish(response_payload, {:routing_key => reply_to, :headers => { :return_status => "200" }})
        end
        channel.acknowledge(delivery_info.delivery_tag, false)
      end
      sc.call(nil)
    end

    def self.run
      conn = Bunny.new(Rails.application.config.acapi.remote_broker_uri, :heartbeat => 15)
      conn.start
      ch = conn.create_channel
      ch.prefetch(1)
      q = ch.queue(queue_name, :durable => true)
      self.new(ch, q).subscribe(:block => true, :manual_ack => true)
      conn.close
    end

    def all_outstanding_shop(exclusion_list)
      enroll_pol_ids = ::Queries::NamedPolicyQueries.all_outstanding_shop
      enroll_pol_ids - exclusion_list
    end

  end
end
