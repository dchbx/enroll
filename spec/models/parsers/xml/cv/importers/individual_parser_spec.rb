require 'rails_helper'

describe Parsers::Xml::Cv::Importers::IndividualParser do
  let(:subject) { Parsers::Xml::Cv::Importers::IndividualParser.new(xml) }

  context "valid verified_family" do
    let(:xml) { File.read(Rails.root.join("spec", "test_data", "individual_person_payloads", "individual.xml")) }

    context "get_person_object" do
      it 'should return the person as an object' do
        expect(subject.get_person_object.class).to eq Person
      end

      it "should get person object with actual person info" do
        person = subject.get_person_object
        expect(person.first_name).to eq "Michael"
        expect(person.middle_name).to eq "J"
        expect(person.last_name).to eq "Green"
      end

      it "should get ssn and hbx_id" do
        person = subject.get_person_object
        expect(person.ssn).to eq "777669999"
        expect(person.hbx_id).to eq "10000123"
      end

      it "should get two addresses" do
        person = subject.get_person_object
        expect(person.addresses.length).to eq 2
        expect(person.addresses.map(&:kind)).to eq ['home', 'mailing']
      end

      it "should get two emails" do
        person = subject.get_person_object
        expect(person.emails.length).to eq 2
        expect(person.emails.map(&:kind)).to eq ['home', 'work']
      end

      it "should get two phones" do
        person = subject.get_person_object
        expect(person.phones.length).to eq 2
        expect(person.phones.map(&:kind)).to eq ['home', 'work']
      end

      it "should get timestamps" do
        person = subject.get_person_object
        expect(person.created_at.present?).to eq true
        expect(person.updated_at.present?).to eq true
      end
    end

    context "get_errors_for_person_object" do
      let(:xml) { File.read(Rails.root.join("spec", "test_data", "individual_person_payloads", "Invalidindividual.xml")) }

      it "should return an array" do
        expect(subject.get_errors_for_person_object.class).to eq Array
      end
    end
  end
end
