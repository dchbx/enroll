require "rails_helper"

require File.join(File.dirname(__FILE__), "../../../../transport_gateway/spec/lint/credentials")

describe TransportProfiles::TransportCredential, "given a URI it does not support credentials for" do
  let(:credential_provider) { TransportProfiles::TransportCredential }
  let(:no_credential_uri) {  URI.parse("file:///2987348973289472397fjskldjaflke") }

  it_behaves_like "a credential provider, given a URI for which it does not have credentials"

end

describe TransportProfiles::TransportCredential, "given an sftp URI it does not have credentials for" do
  let(:credential_provider) { TransportProfiles::TransportCredential }
  let(:no_credential_uri) { URI.parse("ftp://the_sftp_host/some/file") }
  let(:credential_uri) { URI.parse("sftp://the_other_sftp_host/some/file") }
  let(:expected_credentials) { double }

  it_behaves_like "a credential provider, given a URI for which it does not have credentials"

  before(:each) do
    allow(TransportProfiles::TransportCredentials::SftpTransportCredential).to receive(:credentials_for_sftp).with(no_credential_uri).and_return(nil)
    allow(TransportProfiles::TransportCredentials::SftpTransportCredential).to receive(:credentials_for_sftp).with(credential_uri).and_return(expected_credentials)
  end

  it_behaves_like "a credential provider, given a URI for which it has credentials", URI.parse("sftp://the_sftp_host/some/file")

end
