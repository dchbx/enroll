module TransportGateway
  class CredentialResolvers::S3CredentialResolver

    attr_reader :credential_provider, :message

    def initialize(msg, c_provider = nil)
      @message = msg
      @credential_provider = c_provider
    end

    def source_credentials
      [message.source_credentials, credentials_from_provider(message.from)].compact.first
    end

    def destination_credentials
      [message.destination_credentials, credentials_from_provider(message.to)].compact.first
    end

    protected

    def credentials_from_provider(uri)
      return nil if credential_provider.blank?
      credential_provider.credentials_for(uri)
    end
  end
end
