require 'rails_helper'

describe Parsers::Xml::Cv::VerifiedFamilyParser do

  context "valid verified_family" do
    let(:xml) { File.read(Rails.root.join("spec", "test_data", "verified_family_payloads", "valid_verified_family_sample.xml")) }
    let(:subject) { Parsers::Xml::Cv::VerifiedFamilyParser.new }

    it 'should return the elements as a hash' do
      subject.parse(xml)
      expect(subject.to_hash).to include(:integrated_case_id, :family_members, :primary_family_member_id, :households, :submitted_at, :is_active, :created_at)
    end
  end
end
