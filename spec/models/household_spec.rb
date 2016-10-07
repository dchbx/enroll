require 'rails_helper'

describe Household, "given a coverage household with a dependent", :dbclean => :after_each do
  let(:family_member) { FamilyMember.new }
  let(:coverage_household_member) { CoverageHouseholdMember.new(:family_member_id => family_member.id) }
  let(:coverage_household) { CoverageHousehold.new(:coverage_household_members => [coverage_household_member]) }

  subject { Household.new(:coverage_households => [coverage_household]) }

  it "should remove the dependent from the coverage households when removing them from the household" do
    expect(coverage_household).to receive(:remove_family_member).with(family_member)
    subject.remove_family_member(family_member)
  end

  it "should not have any enrolled hbx enrollments" do
    expect(subject.enrolled_hbx_enrollments).to eq []
  end

  it "ImmediateFamily should have domestic partner" do
    expect(Household::ImmediateFamily.include?('domestic_partner')).to eq true
  end

  context "new_hbx_enrollment_from" do
    let(:consumer_role) {FactoryGirl.create(:consumer_role)}
    let(:person) { double(primary_family: family)}
    let(:family) { double }
    let!(:hbx_profile) { FactoryGirl.create(:hbx_profile) }
    let(:benefit_package) { hbx_profile.benefit_sponsorship.benefit_coverage_periods.first.benefit_packages.first }
    let(:coverage_household) {CoverageHousehold.new}
    let(:household) {Household.new}

    before do
      allow(consumer_role).to receive(:person).and_return(person)
      allow(family).to receive(:is_under_special_enrollment_period?).and_return false
      allow(household).to receive(:family).and_return(family)
      allow(family).to receive(:is_under_ivl_open_enrollment?).and_return true
      allow(coverage_household).to receive(:household).and_return(household)
    end

    it "should build hbx enrollment" do
      subject.new_hbx_enrollment_from(
        consumer_role: consumer_role,
        coverage_household: coverage_household,
        benefit_package: benefit_package,
        qle: false
      )
    end
  end

  context "latest_active_tax_household_with_year" do
    let(:family) {FactoryGirl.create(:family, :with_primary_family_member)}
    let!(:household) {FactoryGirl.create(:household, family: family)}
    let(:tax_household) {FactoryGirl.create(:tax_household, household: household, effective_ending_on: nil)}
    let(:tax_household2) {FactoryGirl.create(:tax_household, household: household)}
    let!(:hbx1) {FactoryGirl.create(:hbx_enrollment, household: household, is_active: true, aasm_state: 'coverage_enrolled', changing: false, effective_on: (TimeKeeper.date_of_record.beginning_of_month + 10.days))}

    it "return correct tax_household" do
      household.tax_households << tax_household
      expect(household.latest_active_tax_household_with_year(hbx1.effective_on.year)).to eq tax_household

    end

    it "return nil while current year is not empty" do
      household.tax_households << tax_household2
      expect(household.latest_active_tax_household_with_year(hbx1.effective_on.year)).to be_nil
    end

    it "return nil for not the same year" do
      household.tax_households << tax_household
      expect(household.latest_active_tax_household_with_year((hbx1.effective_on + 1.year).year)).to be_nil
    end

  end

  context "current_year_hbx_enrollments" do
    let(:family) {FactoryGirl.create(:family, :with_primary_family_member)}
    let(:household) {FactoryGirl.create(:household, family: family)}
    let!(:hbx1) {FactoryGirl.create(:hbx_enrollment, household: household, is_active: true, aasm_state: 'coverage_enrolled', changing: false, effective_on: (TimeKeeper.date_of_record.beginning_of_month + 10.days), applied_aptc_amount: 10)}
    let!(:hbx2) {FactoryGirl.create(:hbx_enrollment, household: household, is_active: false)}
    let!(:hbx3) {FactoryGirl.create(:hbx_enrollment, household: household, is_active: true, aasm_state: 'coverage_terminated', changing: false, effective_on: (TimeKeeper.date_of_record.beginning_of_month + 10.days))}
    let!(:hbx4) {FactoryGirl.create(:hbx_enrollment, household: household, is_active: true, aasm_state: 'coverage_enrolled', changing: true)}

    it "should return right hbx_enrollments" do
      household.reload
      expect(household.hbx_enrollments.count).to eq 4
      expect(household.hbx_enrollments_with_aptc_by_year(TimeKeeper.date_of_record.year)).to eq [hbx1]
    end
  end


  context "enrolled_including_waived_hbx_enrollments" do
    let(:family) {FactoryGirl.create(:family, :with_primary_family_member)}
    let(:household) {FactoryGirl.create(:household, family: family)}
    let(:plan1){ FactoryGirl.create(:plan_template, :shop_health) }
    let(:plan2){ FactoryGirl.create(:plan_template, :shop_dental) }

    context "for shop health enrollment" do
      let!(:hbx1) {FactoryGirl.create(:hbx_enrollment, household: household, plan: plan1, is_active: true, aasm_state: 'coverage_selected', changing: false, effective_on: (TimeKeeper.date_of_record.beginning_of_month + 10.days), applied_aptc_amount: 10)}

      it "should return only health hbx enrollment" do
        expect(household.enrolled_including_waived_hbx_enrollments.size).to eq 1
        expect(household.enrolled_including_waived_hbx_enrollments.to_a).to eq [hbx1]
        expect(household.enrolled_including_waived_hbx_enrollments.map(&:plan).map(&:coverage_kind)).to eq ["health"]
      end
    end

    context "for shop dental enrollment" do
      let!(:hbx2) {FactoryGirl.create(:hbx_enrollment, household: household, plan: plan2, is_active: true, aasm_state: 'coverage_selected', changing: false, effective_on: (TimeKeeper.date_of_record.beginning_of_month + 10.days), applied_aptc_amount: 10)}

      it "should return only health hbx enrollment" do
        expect(household.enrolled_including_waived_hbx_enrollments.size).to eq 1
        expect(household.enrolled_including_waived_hbx_enrollments.to_a).to eq [hbx2]
        expect(household.enrolled_including_waived_hbx_enrollments.map(&:plan).map(&:coverage_kind)).to eq ["dental"]
      end
    end

    context "for both shop health and dental enrollment" do
      let!(:hbx1) {FactoryGirl.create(:hbx_enrollment, household: household, plan: plan1, is_active: true, aasm_state: 'coverage_selected', changing: false, coverage_kind: 'dental', effective_on: (TimeKeeper.date_of_record.beginning_of_month + 10.days), applied_aptc_amount: 10)}
      let!(:hbx3) {FactoryGirl.create(:hbx_enrollment, household: household, plan: plan1, is_active: true, aasm_state: 'coverage_selected', changing: false, coverage_kind: 'dental', effective_on: (TimeKeeper.date_of_record.beginning_of_month + 10.days), applied_aptc_amount: 10)}
      let!(:hbx2) {FactoryGirl.create(:hbx_enrollment, household: household, plan: plan2, is_active: true, aasm_state: 'inactive', changing: false, effective_on: (TimeKeeper.date_of_record.beginning_of_month + 10.days), applied_aptc_amount: 10)}
      let!(:hbx4) {FactoryGirl.create(:hbx_enrollment, household: household, plan: plan2, is_active: true, aasm_state: 'inactive', changing: false, effective_on: (TimeKeeper.date_of_record.beginning_of_month + 10.days), applied_aptc_amount: 10)}
      let!(:hbx5) {FactoryGirl.create(:hbx_enrollment, household: household, plan: plan2, is_active: true, aasm_state: 'coverage_enrolled', changing: false, effective_on: (TimeKeeper.date_of_record.beginning_of_month + 10.days), applied_aptc_amount: 10)}

      it "should return the latest hbx enrollments for each shop and dental" do
        expect(household.enrolled_including_waived_hbx_enrollments.size).to eq 2
        expect(household.enrolled_including_waived_hbx_enrollments.to_a).to eq [hbx4, hbx3]
        expect(household.enrolled_including_waived_hbx_enrollments.map(&:plan).map(&:coverage_kind)).to eq ["dental", "health"]
      end
    end

  end



  it "ImmediateFamily should have stepchild" do
    expect(Household::ImmediateFamily.include?('stepchild')).to eq true
  end


  # context "with an enrolled hbx enrollment" do
  #   let(:mock_hbx_enrollment) { instance_double(HbxEnrollment) }
  #   let(:hbx_enrollments) { [mock_hbx_enrollment] }
  #   before do
  #     allow(HbxEnrollment).to receive(:covered).with(hbx_enrollments).and_return(hbx_enrollments)
  #     allow(subject).to receive(:hbx_enrollments).and_return(hbx_enrollments)
  #   end

  #   it "should return the enrolled hbx enrollment in an array" do
  #     expect(subject.enrolled_hbx_enrollments).to eq hbx_enrollments
  #   end
  # end
end


describe Household, "for dependent with domestic partner relationship", type: :model, dbclean: :after_each do
  let(:family) { FactoryGirl.create(:family, :with_primary_family_member, person: person) }
  let(:person) do
    p = FactoryGirl.build(:person)
    p.person_relationships.build(relative: person_two, kind: "domestic_partner")
    p.save
    p
  end
  let(:person_two)  { FactoryGirl.create(:person)}
  let(:family_member) { FactoryGirl.create(:family_member, family: family, person: person_two)}
  before(:each) do
    family.relate_new_member(person_two, "domestic_partner")
    family.save!
  end
  it "should have the extended family member in the extended coverage household" do
     immediate_coverage_members = family.active_household.immediate_family_coverage_household.coverage_household_members
     expect(immediate_coverage_members.length).to eq 2
  end
end
