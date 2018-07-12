# @deprecated This is for the legacy method of dynamic credential resolution.
class TransportProfiles::TransportCredential
  include Mongoid::Document

  def self.credentials_for(uri)
    case uri.scheme
    when "sftp","ftp"
      TransportProfiles::TransportCredentials::SftpTransportCredential.credentials_for_sftp(uri)
    else
      nil
    end
  end
end
