require 'rails_helper'

RSpec.describe TaxHouseholdMember, type: :model do
  let(:current_date) { TimeKeeper.date_of_record }
  let!(:person) { FactoryGirl.create(:person, :with_family, dob: Date.new(1999, 02, 20)) }
  let!(:person2) { FactoryGirl.create(:person, :with_family, dob: Date.new(1999, 02, 20)) }
  let!(:household) { FactoryGirl.create(:household, family: person.primary_family) }
  let!(:tax_household) { FactoryGirl.create(:tax_household, household: household) }
  let!(:tax_household1) { FactoryGirl.create(:tax_household, household: household) }
  let!(:tax_household_member1) { tax_household.tax_household_members.build(applicant_id: person.primary_family.family_members.first.id) }
  let!(:eligibility_kinds1) { { 'is_ia_eligible' => 'true', 'is_medicaid_chip_eligible' => 'true' } }
  let!(:eligibility_kinds2) { { 'is_ia_eligible' => 'true', 'is_medicaid_chip_eligible' => 'false' } }
  let!(:eligibility_kinds3) { { 'is_ia_eligible' => 'false', 'is_medicaid_chip_eligible' => 'false' } }
  let(:eligibility_determination) { FactoryGirl.create(:eligibility_determination, csr_eligibility_kind: 'csr_87', determined_on: current_date, tax_household: tax_household1) }

  context '.include document matchers' do
    it { is_expected.to be_mongoid_document }
  end

  context '.Constants' do
    it 'should have PDC_TYPES constant' do
      subject.class.should be_const_defined(:PDC_TYPES)
      expect(described_class::PDC_TYPES).to eq([['Assisted', 'is_ia_eligible'], ['Medicaid', 'is_medicaid_chip_eligible'], ['Totally Ineligible', 'is_totally_ineligible'], ['UQHP', 'is_uqhp_eligible']])
    end
  end

  context '.modelFeilds' do
    it { is_expected.to have_field(:applicant_id).of_type(BSON::ObjectId) }
    it { is_expected.to have_field(:is_ia_eligible).of_type(Mongoid::Boolean).with_default_value_of(false) }
    it { is_expected.to have_field(:is_medicaid_chip_eligible).of_type(Mongoid::Boolean).with_default_value_of(false) }
    it { is_expected.to have_field(:is_uqhp_eligible).of_type(Mongoid::Boolean).with_default_value_of(false) }
    it { is_expected.to have_field(:is_subscriber).of_type(Mongoid::Boolean).with_default_value_of(false) }
    it { is_expected.to have_field(:is_without_assistance).of_type(Mongoid::Boolean).with_default_value_of(false) }
    it { is_expected.to have_field(:is_totally_ineligible).of_type(Mongoid::Boolean).with_default_value_of(false) }
    it { is_expected.to have_field(:reason).of_type(String) }
  end

  context '.associations' do
    it 'embeded in tax_household' do
      assc = described_class.reflect_on_association(:tax_household)
      expect(assc.macro).to eq :embedded_in
    end
  end

  context '.eligibility_determinations' do
    it 'return eligibility_determinations of THH' do
      eligibility_determination.save!
      expect(tax_household1.eligibility_determinations).to eq eligibility_determination.to_a
    end
  end

  context '.family' do
    it 'returns family of THH' do
      expect(tax_household.family).to eq person.families.first
    end
  end

  context '.person' do
    it 'returns person of THH' do
      expect(tax_household_member1.person).to eq tax_household_member1.family_member.person
    end
  end

  context '.update_eligibility_kinds' do
    it 'should not update and return false when trying to update both the eligibility_kinds as true' do
      expect(tax_household_member1.update_eligibility_kinds(eligibility_kinds1)).to eq false
    end

    it 'should update and return true when trying to update eligibility_kinds other than true for both the fields respectively' do
      expect(tax_household_member1.update_eligibility_kinds(eligibility_kinds2)).to eq true
    end

    it 'should have respective data after updating is_ia_eligible & is_medicaid_chip_eligible' do
      tax_household_member1.update_eligibility_kinds(eligibility_kinds3)
      expect(tax_household_member1.is_ia_eligible).to eq false
      expect(tax_household_member1.is_medicaid_chip_eligible).to eq false
    end
  end

  context '.is_ia_eligible' do
    it 'returns true if is_ia_eligible is true' do
      tax_household_member1.update_attributes(is_ia_eligible: true)
      expect(tax_household_member1.is_ia_eligible).to eq true
    end
    it 'returns false if is_ia_eligible is false' do
      expect(tax_household_member1.is_ia_eligible).to eq false
    end
  end

  context '.non_ia_eligible?' do
    it 'returns true if is_ia_eligible is false' do
      tax_household_member1.update_attributes(is_ia_eligible: false, is_without_assistance: true)
      expect(tax_household_member1.non_ia_eligible?).to eq true
    end
    it 'returns false if is_ia_eligible is true' do
      expect(tax_household_member1.non_ia_eligible?).to eq false
    end
  end

  context '.is_medicaid_chip_eligible' do
    it 'returns true if is_medicaid_chip_eligible is true' do
      tax_household_member1.update_attributes(is_medicaid_chip_eligible: true)
      expect(tax_household_member1.is_medicaid_chip_eligible?).to eq true
    end
    it 'returns false if is_medicaid_chip_eligible is false' do
      expect(tax_household_member1.is_medicaid_chip_eligible?).to eq false
    end
  end

  context 'age_on_effective_date' do
    it 'should return current age for coverage start on month is equal to dob month' do
      tax_household_member1.person.update_attributes(dob: Date.new(1999, current_date.month, current_date.day))
      age = current_date.year - person.dob.year
      expect(tax_household_member1.age_on_effective_date).to eq age
    end

    it 'should return age-1 for coverage start on day is less than dob day' do
      tax_household_member1.person.update_attributes(dob: Date.new(1999, current_date.month, current_date.day) + 1.day)
      age = current_date.year - person.dob.year
      expect(tax_household_member1.age_on_effective_date).to eq age - 1
    end

    it 'should return age-1 for coverage start on month is less to dob month' do
      tax_household_member1.person.update_attributes(dob: Date.new(1999, current_date.month, current_date.day) + 1.month)
      age = current_date.year - person.dob.year
      expect(tax_household_member1.age_on_effective_date).to eq age - 1
    end
  end
end
