module TransportGateway
  class CredentialResolvers::SftpCredentialResolver
    RawSftpCredentials = Struct.new(:user, :password) do
      def sftp_options
        {
          :password => password
        }
      end
    end

    attr_reader :credential_provider, :message

    def initialize(msg, c_provider = nil)
      @message = msg
      @credential_provider = c_provider
    end

    def source_credentials
      [message.source_credentials, parse_uri_credentials(message.from), credentials_from_provider(message.from)].compact.first
    end

    def destination_credentials
      [message.destination_credentials, parse_uri_credentials(message.to), credentials_from_provider(message.to)].compact.first
    end

    protected

    def credentials_from_provider(uri)
      return nil if credential_provider.blank?
      credential_provider.credentials_for(uri)
    end

    def parse_uri_credentials(uri)
      return nil if uri.user.blank? || uri.password.blank?
      user     = URI.decode(uri.user)
      password = URI.decode(uri.password)
      RawSftpCredentials.new(user, password)
    end
  end
end
