require "rails_helper"

RSpec.shared_examples "a credential provider, given a URI for which it has credentials" do
  it "looks up the credentials correctly" do
    expect(credential_provider.credentials_for(credential_uri)).to eq(expected_credentials)
  end
end

RSpec.shared_examples "a credential provider, given a URI for which it does not have credentials" do
  it "returns nothing" do
    expect(credential_provider.credentials_for(no_credential_uri)).to eq nil
  end
end
