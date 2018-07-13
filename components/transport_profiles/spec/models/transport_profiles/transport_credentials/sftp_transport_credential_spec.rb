require "rails_helper"

require File.join(File.dirname(__FILE__), "../../../../../transport_gateway/spec/lint/credentials/sftp_credentials")

describe TransportProfiles::TransportCredentials::SftpTransportCredential, ".credentials_for_sftp" do

  describe "given a uri which has no userinfo" do
    let(:no_credential_uri) { URI.parse("ftp:///alksjdfkljef") }

    it "finds nothing" do
      expect(TransportProfiles::TransportCredentials::SftpTransportCredential.credentials_for_sftp(no_credential_uri)).to eq nil
    end
  end

  describe "given a uri which has no user in the userinfo" do
    let(:no_credential_uri) { URI.parse("ftp:///:kkjljsf@something.com/") }

    it "finds nothing" do
      expect(TransportProfiles::TransportCredentials::SftpTransportCredential.credentials_for_sftp(no_credential_uri)).to eq nil
    end
  end

  describe "given a uri for same user and host name as an existing record" do
    let(:username) { "user#($&#$&:;\"{)_#@^" }
    let(:credential_uri) { URI.parse("sftp://#{ERB::Util.url_encode(username)}@host1.com") }
    let!(:credential) do
      TransportProfiles::TransportCredentials::SftpTransportCredential.create!({
        :user => username,
        :host => "host1.com",
        :password => "NOTHING"
      })
    end
   
    after :each do
      credential.destroy
    end

    it "finds the matching credentials" do
      expect(TransportProfiles::TransportCredentials::SftpTransportCredential.credentials_for_sftp(credential_uri)).to eq credential
    end
  end

  describe "given a uri for same user and a DIFFERENT host name as an existing record" do
    let(:username) { "user#($&#$&:;\"{)_#@^" }
    let(:no_credential_uri) { URI.parse("sftp://#{ERB::Util.url_encode(username)}@host2.com") }
    let!(:credential) do
      TransportProfiles::TransportCredentials::SftpTransportCredential.create!({
        :user => username,
        :host => "host1.com",
        :password => "NOTHING"
      })
    end
   
    after :each do
      credential.destroy
    end

    it "finds nothing" do
      expect(TransportProfiles::TransportCredentials::SftpTransportCredential.credentials_for_sftp(no_credential_uri)).to eq nil
    end
  end

end

describe TransportProfiles::TransportCredentials::SftpTransportCredential, "given:
- a user
- a password
" do
  let(:expected_user) { "user1" }
  let(:expected_password) { "password1" }
  let(:host) { "host1" }
  let(:sftp_credentials) do
    TransportProfiles::TransportCredentials::SftpTransportCredential.new({
      :user => expected_user,
      :password => expected_password,
      :host => host
    })
  end
  it_behaves_like "sftp credentials, using a password"
end

describe TransportProfiles::TransportCredentials::SftpTransportCredential, "given:
- a user
- a key pem 
" do
  let(:expected_user) { "user1" }
  let(:expected_key_pem) { "98273498712983740983742(*&34043" }
  let(:host) { "host1" }
  let(:sftp_credentials) do
    TransportProfiles::TransportCredentials::SftpTransportCredential.new({
      :user => expected_user,
      :key_pem => expected_key_pem,
      :host => host
    })
  end
  it_behaves_like "sftp credentials, using a key pem"
end

describe TransportProfiles::TransportCredentials::SftpTransportCredential do
  it "is invalid without a user" do
    subject.valid?
    expect(subject.errors.keys).to include(:user)
  end

  it "is invalid without a host" do
    subject.valid?
    expect(subject.errors.keys).to include(:host)
  end

  it "is invalid without a password or key_pem" do
    subject.valid?
    expect(subject.errors.keys).to include(:password)
    expect(subject.errors.keys).to include(:key_pem)
  end

  describe "given a password" do
    it "does not require a key_pem" do
      subject.password = "some_password"
      subject.valid?
      expect(subject.errors.keys).not_to include(:key_pem)
    end
  end

  describe "given a key_pem" do
    it "does not require a password" do
      subject.key_pem = "some_key_pem"
      subject.valid?
      expect(subject.errors.keys).not_to include(:password)
    end
  end
end
