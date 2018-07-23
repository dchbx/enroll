require "rails_helper"

require File.join(File.dirname(__FILE__), "../../../../transport_gateway/spec/lint/credentials/sftp_credentials")
require File.join(File.dirname(__FILE__), "../../../../transport_gateway/spec/lint/credentials/s3_credentials")

describe TransportProfiles::WellKnownEndpoint, "given sftp credentials with:
- an account name
- an account password
" do
  let(:expected_user) { "user1" }
  let(:expected_password) { "password1" }
  let(:sftp_credentials) do
    TransportProfiles::WellKnownEndpoint.new({
      title: "Test URI",
      site_key: "some site key",
      key: "a key",
      market_kind: "shop",
      uri: "s3://bucket@region/some_key",
      credentials: [
         TransportProfiles::Credential.new(
            account_name: expected_user,
            pass_phrase: expected_password,
            credential_kind: "sftp"
         )
      ]
    })
  end
  it_behaves_like "sftp credentials, using a password"
end

describe TransportProfiles::WellKnownEndpoint, "given sftp credentials with:
- an account name
- an private rsa key
" do
  let(:expected_user) { "user1" }
  let(:expected_key_pem) { "98273498712983740983742(*&34043" }
  let(:sftp_credentials) do
    TransportProfiles::WellKnownEndpoint.new({
      title: "Test URI",
      site_key: "some site key",
      key: "a key",
      market_kind: "shop",
      uri: "s3://bucket@region/some_key",
      credentials: [
        TransportProfiles::Credential.new(
          account_name: expected_user,
          private_rsa_key: expected_key_pem,
          credential_kind: "sftp"
        )
      ]
    })
  end
  it_behaves_like "sftp credentials, using a key pem"
end

describe TransportProfiles::WellKnownEndpoint, "given s3 credentials with:
- an access key id
- a secret access key
" do
  let(:expected_access_key_id) { "access key id" }
  let(:expected_secret_access_key) { "98273498712983740983742(*&34043" }
  let(:s3_credentials) do
    TransportProfiles::WellKnownEndpoint.new({
      title: "Test URI",
      site_key: "some site key",
      key: "a key",
      market_kind: "shop",
      uri: "s3://bucket@region/some_key",
      credentials: [
        TransportProfiles::Credential.new(
          access_key_id: expected_access_key_id,
          secret_access_key: expected_secret_access_key,
          credential_kind: "s3"
        )
      ]
    })
  end
  it_behaves_like "transport gateway s3 credentials"
end
