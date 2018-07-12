# @deprecated This is for the legacy method of dynamic credential resolution.
module TransportProfiles::TransportCredentials
  # @deprecated This is for the legacy method of dynamic credential resolution.
  class SftpTransportCredential < TransportProfiles::TransportCredential
    field :user, type: String
    field :host, type: String

    field :encrypted_password, type: String
    field :encrypted_key_pem, type: String

    validates_presence_of :user, :allow_blank => false
    validates_presence_of :host, :allow_blank => false
    validates_presence_of :password, :allow_blank => false, :if => ->(record) { record.key_pem.blank? }
    validates_presence_of :key_pem, :allow_blank => false, :if => ->(record) { record.password.blank? }

    def key_pem 
      SymmetricEncryption.decrypt(encrypted_key_pem)
    end

    def key_pem=(val)
      write_attribute(:encrypted_key_pem, SymmetricEncryption.encrypt(val))
    end

    def password
      SymmetricEncryption.decrypt(encrypted_password)
    end

    def password=(val)
      write_attribute(:encrypted_password, SymmetricEncryption.encrypt(val))
    end

    def self.credentials_for_sftp(uri)
      return nil if uri.userinfo.blank?
      return nil if uri.user.blank?
      lookup_username = URI.decode(uri.user)
      self.where({user: lookup_username, host: uri.host}).first
    end

    def sftp_options
      if key_pem.blank?
        { :password => password }
      else
        { :key_data => [key_pem] }
      end
    end
  end
end
