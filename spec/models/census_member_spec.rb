require 'rails_helper'

RSpec.describe CensusMember, :dbclean => :after_each do
  it { should validate_presence_of :first_name }
  it { should validate_presence_of :last_name }
  it { should validate_presence_of :dob }
  
  let(:employer_profile)  { FactoryGirl.create(:employer_profile) }
  let(:census_employee) { FactoryGirl.create(:census_employee, employer_profile: employer_profile) }

  it "sets gender" do
    census_employee.gender = "MALE"
    expect(census_employee.gender).to eq "male"
  end

  it "sets date of birth" do
    census_employee.date_of_birth = "1980-12-12"
    expect(census_employee.dob).to eq "1980-12-12".to_date
  end

  context "dob" do
    before(:each) do
      census_employee.date_of_birth = "1980-12-01"
    end

    it "dob_string" do
      expect(census_employee.dob_string).to eq "19801201"
    end

    it "date_of_birth" do
      expect(census_employee.date_of_birth).to eq "12/01/1980"
    end

    context "dob more than 110 years ago" do
      before(:each) do
        census_employee.dob = 111.years.ago
      end

      it "generate validation error" do
        expect(census_employee.valid?).to be_falsey
        expect(census_employee.errors.full_messages).to include("Dob date cannot be more than 110 years ago")
      end
    end
  end

  context "validate of date_of_birth_is_past" do
    it "should invalid" do
      dob = (Date.today + 10.days)
      census_employee.date_of_birth = dob.strftime("%Y-%m-%d")
      expect(census_employee.save).to be_falsey
      expect(census_employee.errors[:dob].any?).to be_truthy
      expect(census_employee.errors[:dob].to_s).to match /future date: #{dob.to_s} is invalid date of birth/
    end
  end

  context "without a gender" do
    it "should be invalid" do
      expect(census_employee.valid?).to eq true
      census_employee.gender = nil
      expect(census_employee.valid?).to eq false
      expect(census_employee).to have_errors_on(:gender)
    end
  end
end
