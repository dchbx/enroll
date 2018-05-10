require 'rails_helper'
describe Forms::ConsumerCandidate, "asked to match a person" do

  let(:user){ create(:user) }
  let(:person) { create(:person, :with_ssn, user: user) }

  let(:params) { {
    :dob => "2012-10-12",
    :ssn => person.ssn,
    :first_name => "yo",
    :last_name => "guy",
    :gender => "m",
    :user_id => 20,
    :is_applying_coverage => false
    } }

  let(:subject) { Forms::ConsumerCandidate.new(params) }

  context "uniq ssn" do
    
    context 'when ssn blank' do
      let(:params) { {:ssn => nil} }

      it "return true " do
        expect(subject.uniq_ssn).to eq true
      end
    end

    context 'when ssn matches with claimed user account' do
      it "should add errors" do
        subject.uniq_ssn
        expect(subject.errors[:ssn_taken]).to eq ["The social security number you entered is affiliated with another account."]
      end
    end

    context 'when ssn matches with unclaimed user account' do 
      let(:person) { create(:person, :with_ssn) }

      it "should not add errors" do
        subject.uniq_ssn
        expect(subject.errors[:base]).to eq []
      end
    end
  end

  context "uniq ssn & dob" do

    context 'when ssn blank' do
      let(:params) { {:ssn => nil} }

      it "return true " do
        expect(subject.uniq_ssn_dob).to eq true
      end
    end

    context 'when ssn & dob combination did not match with existing person' do
      let(:params) { {:ssn => person.ssn, :dob => "2012-10-12"} }

      it "should add errors" do
        subject.uniq_ssn_dob
        expect(subject.errors[:base]).to eq ["This Social Security Number and Date-of-Birth is invalid in our records.  Please verify the entry, and if correct, contact the DC Customer help center at #{Settings.contact_center.phone_number}."]
      end
    end

    context "does not add errors when ssn & dob matches with existing person record" do
  
      let(:params) { {:ssn => person.ssn, :dob => person.dob.strftime("%Y-%m-%d")} }
    
      it 'should not add errors' do 
        subject.uniq_ssn_dob
        expect(subject.errors[:base]).to eq []
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
                                     :user_id => 20,
                                     :is_applying_coverage => false
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



describe Forms::ConsumerCandidate, "ssn validations" do
  let(:person) {FactoryGirl.create(:person)}

  before do
    allow(Person).to receive(:where).and_return([person])
    allow(person).to receive(:user).and_return(true)
  end

  context "is applying coverage is TRUE" do
    subject { Forms::ConsumerCandidate.new({:dob => "2012-10-12", :ssn => "453213333", :first_name => "yo", :last_name => "guy",
                                        :gender => "m", :user_id => 20, :is_applying_coverage => "true" })}

    it "add errors when SSN is blank" do
      allow(subject).to receive(:ssn).and_return("")
      allow(subject).to receive(:no_ssn).and_return("0")
      subject.ssn_or_checkbox
      expect(subject.errors.messages.present?).to eq true
    end

    it "doesnt add errors when SSN is present" do
      allow(subject).to receive(:ssn).and_return("453213333")
      allow(subject).to receive(:no_ssn).and_return("0")
      expect(subject.errors.messages.present?).to eq false
    end
  end

  context "is applying coverage is FALSE" do
    subject { Forms::ConsumerCandidate.new({:dob => "2012-10-12", :ssn => "453213333", :first_name => "yo", :last_name => "guy",
                                    :gender => "m", :user_id => 20, :is_applying_coverage => "false" })}

    it "doesnt add errors when SSN is blank" do
      allow(subject).to receive(:ssn).and_return("")
      allow(subject).to receive(:no_ssn).and_return("0")
      subject.ssn_or_checkbox
      expect(subject.errors.messages.present?).to eq false
    end

    it "doesnt add errors when SSN is present" do
      allow(subject).to receive(:ssn).and_return("453213333")
      allow(subject).to receive(:no_ssn).and_return("0")
      subject.ssn_or_checkbox
      expect(subject.errors.messages.present?).to eq false
    end
  end
end
