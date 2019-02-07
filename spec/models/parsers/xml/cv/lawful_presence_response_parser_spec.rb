require 'rails_helper'

describe Parsers::Xml::Cv::LawfulPresenceResponseParser do

  context "lawful_presence_indeterminate" do
    let(:xml) { File.read(Rails.root.join("spec", "test_data", "lawful_presence_payloads", "response.xml")) }
    let(:subject) { Parsers::Xml::Cv::LawfulPresenceResponseParser.new }

    it 'should return the hash' do
      subject.parse(xml)
      expect(subject.to_hash).to include(:case_number, :lawful_presence_indeterminate)
      expect(subject.to_hash[:lawful_presence_indeterminate]).to include(:response_code, :response_text)

    end
  end


  context "lawful_presence_determination" do
    let(:xml) { File.read(Rails.root.join("spec", "test_data", "lawful_presence_payloads", "response2.xml")) }
    let(:subject) { Parsers::Xml::Cv::LawfulPresenceResponseParser.new }

    it 'should return the hash' do
      subject.parse(xml)
      expect(subject.to_hash).to include(:case_number, :lawful_presence_determination)
      expect(subject.to_hash[:lawful_presence_determination][:document_results]).to include(:document_foreign_passport, :document_cert_of_naturalization)
      expect(subject.to_hash[:lawful_presence_determination]).to include(:qualified_non_citizen_code)
    end
  end

end
