module TransportProfiles
  module Subscribers
    class TransportArtifactSubscriber
      include Acapi::Notifiers

      def self.worker_specification
        Acapi::Amqp::WorkerSpecification.new(
          :queue_name => "transport_artifact_subscriber",
          :kind => :direct,
          :routing_key => "info.events.transport_artifact.transport_requested"
        )
      end

      def work_with_params(body, delivery_info, properties)
        headers = properties.headers || {}
        stringed_payload = headers.stringify_keys
        artifact_key = stringed_payload["artifact_key"]
        file_name = stringed_payload["file_name"]
        transport_process = stringed_payload["transport_process"]
        atr = ::TransportProfiles::ArtifactTransportRequest.new(
          :file_name => file_name,
          :artifact_key => artifact_key,
          :transport_process => transport_process
        )
        if !atr.valid?
          notify(
            "acapi.error.events.transport_artifact.invalid_transport_request",
            {
              :return_status => "422",
              :body => JSON.dump(
                atr.errors.to_hash
              )
            }
          )
          return :ack
        end
        atr.execute
        :ack
      end
    end
  end
end
