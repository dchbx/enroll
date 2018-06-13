require "rails_helper"

RSpec.shared_examples_for "transport gateway s3 credentials" do

  it "provides the expected access key" do
    expect(s3_credentials.s3_options[:access_key_id]).to eq expected_access_key_id
  end

  it "provides the expected secret access key" do
    expect(s3_credentials.s3_options[:secret_access_key]).to eq expected_secret_access_key
  end

end
