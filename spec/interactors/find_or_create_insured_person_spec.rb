require "rails_helper"

describe FindOrCreateInsuredPerson, :dbclean => :after_each do
  let(:first_name) { "Joe" }
  let(:last_name) { "Smith" }
  let(:dob) { Date.new(1988, 3, 10) }
  let(:ssn) { "989834231" }
  let(:user) { double }
  let(:result) { FindOrCreateInsuredPerson.call(context_arguments) }

  context "given a person who does not exist" do
    let(:new_person) { double }
    let(:context_arguments) {
      { :first_name => first_name,
      :last_name => last_name,
      :dob => dob }
    }

    before :each do
      allow(Person).to receive(:match_by_id_info).with(ssn: nil, dob: dob, first_name: first_name, last_name: last_name).and_return([])
      allow(Person).to receive(:create).with(
        user: nil,
        name_pfx: nil,
        first_name: first_name, 
        middle_name: nil,
        last_name: last_name,
        name_sfx: nil,
        ssn: nil,
        no_ssn: nil,
        dob: dob,
        gender: nil).and_return(new_person)
    end

    it "should create that person and return them" do
      expect(result.person).to eq new_person
    end

    it "should communicate it created a new person" do
      expect(result.is_new).to be_truthy
    end
  end

  context "given a person who does exist" do
    let(:found_person) { double(ssn: ssn, save: true) }
    let(:context_arguments) {
      { :first_name => first_name,
        :last_name => last_name,
        :dob => dob }
    }

    before :each do
      allow(Person).to receive(:match_by_id_info).with(ssn: nil, dob: dob, first_name: first_name, last_name: last_name).and_return([found_person])
    end

    it "should return the found person" do
      expect(result.person).to eq found_person
    end

    it "should communicate that a new person was not created" do
      expect(result.is_new).to be_falsey
    end
  end
end
