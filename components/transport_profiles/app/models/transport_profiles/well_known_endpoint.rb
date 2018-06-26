module TransportProfiles
  # Defines an endpoint from which to transport resources from or to.
  # Includes embedded {TransportProfiles::Credential} records to specify authentication information.
  class WellKnownEndpoint
    include Mongoid::Document

    # Required.  A descriptive title for this endpoint.
    field :title, type: String

    # Required.  Specifies the exchange using this endpoint, such as 'dc0' or 'ma0'.
    field :site_key, type: String

    # Required. Specifies the 'friendly name' which will be referenced using a symbol during steps and processes.
    field :key, type: String

    field :market_kind, type: String

    # Required. Specifies the connection URI.
    field :uri, type: String

    embeds_many :credentials, class_name: "TransportProfiles::Credential"

    validates_presence_of :title, :site_key, :key, :uri

    MARKET_KINDS = ["shop", "individual", "any"]

    validates_inclusion_of :market_kind, in: MARKET_KINDS, message: '%{value} is not a valid market kind', :allow_nil => false

    index({key: 1})
    index({site_key: 1, key: 1, market_kind: 1})

    scope :find_by_endpoint_key,  ->(endpoint_key) { where(key: endpoint_key.to_s ) }

    def active_credential
      credentials.first
    end

    def user
      sftp_credential = credentials.detect { |cr| cr.sftp? }
      sftp_credential.account_name
    end

    def s3_options
      s3_credential = credentials.detect { |cr| cr.s3? }
      return nil unless s3_credential
      {
        secret_access_key: s3_credential.secret_access_key,
        access_key_id: s3_credential.access_key_id
      }
    end

    def sftp_options
      sftp_credential = credentials.detect { |cr| cr.sftp? }
      return nil unless sftp_credential
      if sftp_credential.private_rsa_key.blank?
        {
          user: sftp_credential.account_name,
          password: sftp_credential.pass_phrase
        }
      else
        {
          user: sftp_credential.account_name,
          key_data: [sftp_credential.private_rsa_key]
        }
      end
    end
  end
end
