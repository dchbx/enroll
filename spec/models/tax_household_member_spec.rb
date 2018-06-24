require 'rails_helper'

RSpec.describe TaxHouseholdMember, type: :model do
  let!(:person) {FactoryGirl.create(:person, :with_family, dob: Date.new(1999, 02, 20))}
  let!(:household) {FactoryGirl.create(:household, family: person.primary_family)}
  let!(:tax_household) {FactoryGirl.create(:tax_household, household: household)}
  let!(:tax_household_member1) {tax_household.tax_household_members.build(applicant_id: person.primary_family.family_members.first.id)}
  let!(:eligibility_kinds1) {{"is_ia_eligible" => "true", "is_medicaid_chip_eligible" => "true"}}
  let!(:eligibility_kinds2) {{"is_ia_eligible" => "true", "is_medicaid_chip_eligible" => "false"}}
  let!(:eligibility_kinds3) {{"is_ia_eligible" => "false", "is_medicaid_chip_eligible" => "false"}}


  context "update_eligibility_kinds" do
    it "should not update and return false when trying to update both the eligibility_kinds as true" do
      expect(tax_household_member1.update_eligibility_kinds(eligibility_kinds1)).to eq false
    end

    it "should update and return true when trying to update eligibility_kinds other than true for both the fields respectively" do
      expect(tax_household_member1.update_eligibility_kinds(eligibility_kinds2)).to eq true
    end

    it "should have respective data after updating is_ia_eligible & is_medicaid_chip_eligible" do
      tax_household_member1.update_eligibility_kinds(eligibility_kinds3)
      expect(tax_household_member1.is_ia_eligible).to eq false
      expect(tax_household_member1.is_medicaid_chip_eligible).to eq false
    end
  end

  context "age_on_effective_date" do
    it "should return current age for coverage start on month is equal to dob month" do
      age = TimeKeeper.date_of_record.year-person.dob.year
      expect(tax_household_member1.age_on_effective_date).to eq age
    end

    it "should return age-1 for coverage start on month is less than dob month" do
      tax_household_member1.person.update_attributes(dob: Date.new(1999, TimeKeeper.date_of_record.month, TimeKeeper.date_of_record.day) + 1.day)
      age = TimeKeeper.date_of_record.year-person.dob.year
      expect(tax_household_member1.age_on_effective_date).to eq age-1
    end

    it "should return age-1 for coverage start on day is less to dob day" do
      tax_household_member1.person.update_attributes(dob: Date.new(1999, TimeKeeper.date_of_record.month, TimeKeeper.date_of_record.day) + 1.month)
      age = TimeKeeper.date_of_record.year-person.dob.year
      expect(tax_household_member1.age_on_effective_date).to eq age-1
    end
  end
end
