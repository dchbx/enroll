require "rails_helper"

describe URI::S3, "given an s3 uri" do
  subject { URI.parse("s3://bucket@region/object_key/with_extra/delimiters") }

  it "returns an s3 uri" do
    expect(subject.kind_of?(URI::S3)).to be_truthy
  end

  it "has the correct bucket" do
    expect(subject.bucket).to eq "bucket"
  end

  it "has the correct region" do
    expect(subject.region).to eq "region"
  end

  it "has the key" do
    expect(subject.key).to eq "object_key/with_extra/delimiters"
  end
end
