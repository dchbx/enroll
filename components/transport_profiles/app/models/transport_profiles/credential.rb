module TransportProfiles
  class Credential
    include Mongoid::Document

    embedded_in :well_known_endpoint, class_name: "TransportProfiles::WellKnownEndpoint"

    field :account_name, type: String
    field :access_key_id, type: String
    field :secret_access_key, type: String
    field :credential_kind, type: String

    field :encrypted_pass_phrase, type: String
    field :encrypted_private_rsa_key, type: String
    field :encrypted_secret_access_key, type: String

    def secret_access_key
      SymmetricEncryption.decrypt(encrypted_secret_access_key)
    end

    def secret_access_key=(val)
      write_attribute(:encrypted_secret_access_key, SymmetricEncryption.encrypt(val))
    end

    def pass_phrase
      SymmetricEncryption.decrypt(encrypted_pass_phrase)
    end

    def pass_phrase=(val)
      write_attribute(:encrypted_pass_phrase, SymmetricEncryption.encrypt(val))
    end

    def private_rsa_key
      SymmetricEncryption.decrypt(encrypted_private_rsa_key)
    end

    def private_rsa_key=(val)
      write_attribute(:encrypted_private_rsa_key, SymmetricEncryption.encrypt(val))
    end

    def sftp?
      self.credential_kind == "sftp"
    end

    def s3?
      self.credential_kind == "s3"
    end

    def export_key
    end

    def update_key(file_path)
      File.read(file_path)
    end

  end
end
