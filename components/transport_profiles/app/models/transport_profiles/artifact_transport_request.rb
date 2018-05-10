module TransportProfiles
  class ArtifactTransportRequest
    include ActiveModel::Model
    include ActiveModel::Validations

    attr_accessor :file_name, :artifact_key, :transport_process

    validates_presence_of :file_name, :allow_blank => false
    validates_presence_of :artifact_key, :allow_blank => false
    validates_presence_of :transport_process, :allow_blank => false

    validate :transport_process_resolves

    def transport_process_resolves
      return false if transport_process.blank?
      begin
        get_transport_process_class
        return true
      rescue NameError => e
        errors.add(:transport_process, "#{transport_process} is an invalid transport process")
        return false
      end
    end

    def get_transport_process_class
      @transport_class ||= self.class.const_get("::TransportProfiles::Processes::#{transport_process}")
    end
    
    def execute
      gateway = TransportGateway::Gateway.new(nil, Rails.logger)
      transfer_endpoint = TransportProfiles::WellKnownEndpoint.find_by_endpoint_key("aca_internal_artifact_transport").first
      process = get_transport_process_class.new(extract_artifact_uri(transfer_endpoint), gateway, destination_file_name: file_name, source_credentials: transfer_endpoint)
      process.execute
    end

    def extract_artifact_uri(transfer_endpoint)
      URI.join(transfer_endpoint.uri, artifact_key)
    end
  end
end
