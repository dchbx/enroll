require "rails_helper"

if ExchangeTestingConfigurationHelper.individual_market_is_enabled?
describe IdentityVerification::InteractiveVerificationOverrideResponse do
  let(:response_data) { File.read(file_path) }
  subject {
    IdentityVerification::InteractiveVerificationOverrideResponse.parse(response_data, :single => true)
  }

  describe "given a successful response" do
    let(:file_path) { File.join(Rails.root, "spec", "test_data", "ridp_payloads", "successful_fars_response.xml") }
    let(:expected_response_text) { "FARS passed."}
    let(:expected_transaction_id) { "WhateverRefNumberHere" }

    it "should be considered successful" do
      expect(subject.successful?).to eq true
    end

    it "should have the correct response text" do
      expect(subject.response_text).to eq expected_response_text
    end

    it "should have the correct transaction_id" do
      expect(subject.transaction_id).to eq expected_transaction_id
    end

  end

  describe "given a failed response" do
    let(:file_path) { File.join(Rails.root, "spec", "test_data", "ridp_payloads", "failed_fars_response.xml") }
    let(:expected_response_text) { "NEVER HEARD OF YA" }
    let(:expected_transaction_id) { "WhateverRefNumberHere" }

    it "should not be considered successful" do
      expect(subject.successful?).to eq false
    end

    it "should have the correct response text" do
      expect(subject.response_text).to eq expected_response_text
    end

    it "should have the correct transaction_id" do
      expect(subject.transaction_id).to eq expected_transaction_id
    end

  end
end
end
