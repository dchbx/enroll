require 'rails_helper'
describe Forms::ConsumerCandidate, "asked to match a person" do

  subject {
    Forms::ConsumerCandidate.new({
                                     :dob => "1982-10-12",
                                     :ssn => "123-45-6789",
                                     :first_name => "yo",
                                     :last_name => "guy",
                                     :gender => "m",
                                     :user_id => 20
                                 })
  }
  let(:person) {FactoryGirl.create(:person)}
  context "uniq ssn" do
    it "return true when ssn is blank" do
      allow(subject).to receive(:ssn).and_return(nil)
      expect(subject.uniq_ssn).to eq true
    end

    it "add errors when duplicated ssn with a user account" do
      allow(subject).to receive(:ssn).and_return("123456789")
      allow(Person).to receive(:where).and_return([person])
      allow(person).to receive(:user).and_return(true)
      subject.uniq_ssn
      expect(subject.errors[:ssn_taken]).to eq ["The social security number you entered is affiliated with another account."]
    end

    it "does not add errors when duplicated ssn and no account" do
      allow(subject).to receive(:ssn).and_return("123456789")
      allow(Person).to receive(:where).and_return([person])
      allow(person).to receive(:user).and_return(false)
      subject.uniq_ssn
      expect(subject.errors[:base]).to eq []
    end

    describe "applying for coverage" do
      before do
        allow(subject).to receive(:is_applying_coverage?).and_return true
        subject.ssn_or_checkbox
      end
      it "pass validation" do
        expect(subject).to be_valid
      end

      it "fails validation with ssn or ssn checkbox" do
        allow(subject).to receive(:ssn).and_return(nil)
        allow(subject).to receive(:no_ssn).and_return("0")
        expect(subject).not_to be_valid
        expect(subject.errors[:base]).to eq ["Check No SSN box or enter a valid SSN"]
      end
    end

    describe "NOT applying for coverage" do
      before do
        allow(subject).to receive(:is_applying_coverage?).and_return false
        subject.ssn_or_checkbox
      end
      it "pass validation" do
        expect(subject).to be_valid
      end

      it "fails validation with ssn or ssn checkbox" do
        allow(subject).to receive(:ssn).and_return(nil)
        allow(subject).to receive(:no_ssn).and_return("0")
        expect(subject).to be_valid
      end
    end

  end
end


describe "match a person in db" do
  let(:subject) {
    Forms::ConsumerCandidate.new({
                                     :dob => search_params.dob,
                                     :ssn => search_params.ssn,
                                     :first_name => search_param_name.first_name,
                                     :last_name => search_param_name.last_name,
                                     :gender => "m",
                                     :user_id => 20
                                 })
  }

  let(:search_params) { double(dob: db_person.dob.strftime("%Y-%m-%d"), ssn: db_person.ssn, )}
  let(:search_param_name) { double( first_name: db_person.first_name, last_name: db_person.last_name)}

  after(:each) do
    DatabaseCleaner.clean
  end

  context "with a person with a first name, last name, dob and no SSN" do
    let(:db_person) { Person.create!(first_name: "Joe", last_name: "Kramer", dob: "1993-03-30", ssn: '')}

    it 'matches the person by last_name, first name and dob if there is no ssn' do
      expect(subject.match_person).to eq db_person
    end

    it 'matches the person ingoring case' do
      subject.first_name.upcase!
      subject.last_name.downcase!
      expect(subject.match_person).to eq db_person
    end

    context "with a person who has no ssn but an employer staff role" do
      let(:employer_staff_role) { EmployerStaffRole.create(person: db_person, employer_profile_id: "1") }

      it 'matches person by last name, first name and dob' do
        db_person.employer_staff_roles << employer_staff_role
        db_person.save!
        allow(search_params).to receive(:ssn).and_return("517991234")
        expect(subject.match_person).to eq db_person
      end
    end
  end

  context "with a person with a first name, last name, dob and ssn" do
    let(:db_person) { Person.create!(first_name: "Jack",   last_name: "Weiner",   dob: "1943-05-14", ssn: "517994321")}

    it 'matches the person by ssn and dob' do
      expect(subject.match_person).to eq db_person
    end

    it 'does not find the person if payload has a different ssn from the person' do
      subject.ssn = "888891234"
      expect(subject.match_person).to eq nil
    end
  end
end
