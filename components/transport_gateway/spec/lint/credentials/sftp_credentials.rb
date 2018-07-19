require "rails_helper"

RSpec.shared_examples_for "sftp credentials" do
  it "provides the expected user" do
    expect(sftp_credentials.user).to eq expected_user
  end
end

RSpec.shared_examples_for "sftp credentials, using a password" do
  it_behaves_like "sftp credentials"

  it "provides sftp options for the expected password" do
    expect(sftp_credentials.sftp_options[:password]).to eq expected_password
  end
end

RSpec.shared_examples_for "sftp credentials, using a key pem" do
  it_behaves_like "sftp credentials"

  it "provides sftp options for the expected key" do
    expect(sftp_credentials.sftp_options[:key_data]).to eq [expected_key_pem]
  end
end
