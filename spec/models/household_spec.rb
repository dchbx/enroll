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
    expect(Family::IMMEDIATE_FAMILY.include?('stepchild')).to eq true
  end

  context "eligibility determinations for a household" do
    #let!(:tax_household1) {FactoryGirl.create(:tax_household }
    let(:year) { TimeKeeper.date_of_record.year }
    let(:family) {FactoryGirl.create(:family, :with_primary_family_member)}
    let!(:household) {FactoryGirl.create(:household, family: family)}
    let(:tax_household1) {FactoryGirl.create(:tax_household, household: household)}
    let(:tax_household2) {FactoryGirl.create(:tax_household, household: household)}
    let(:tax_household3) {FactoryGirl.create(:tax_household, household: household)}
    let(:eligibility_determination1) {FactoryGirl.create(:eligibility_determination, tax_household: tax_household1)}
    let(:eligibility_determination2) {FactoryGirl.create(:eligibility_determination, tax_household: tax_household2)}
    let(:eligibility_determination3) {FactoryGirl.create(:eligibility_determination, tax_household: tax_household3)}

    it "should return all the eligibility determinations across all tax households when there is one eligibility determination per tax household" do
      tax_household1.eligibility_determinations = [eligibility_determination1]
      tax_household2.eligibility_determinations = [eligibility_determination2]
      household.tax_households = [tax_household1, tax_household2]
      expect(household.eligibility_determinations_for_year(year).size).to eq 2
      household.eligibility_determinations_for_year(year).each do |ed|
        expect(household.eligibility_determinations_for_year(year)).to include(ed)
      end
    end

    it "should return all the eligibility determinations across all tax households when there is more than one eligibility determination in some tax household" do
      tax_household1.eligibility_determinations = [eligibility_determination1, eligibility_determination3]
      tax_household2.eligibility_determinations = [eligibility_determination2]
      household.tax_households = [tax_household1, tax_household2]
      expect(household.eligibility_determinations_for_year(year).size).to eq 3
      household.eligibility_determinations_for_year(year).each do |ed|
        expect(household.eligibility_determinations_for_year(year)).to include(ed)
      end
    end
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

describe "multiple taxhouseholds for a family", type: :model, dbclean: :after_each do
  let!(:person) { FactoryGirl.create(:person, :with_family) }
  let!(:household) { person.primary_family.households.first }
  let!(:tax_household1) { FactoryGirl.create(:tax_household, household: household, effective_starting_on: Date.new(TimeKeeper.date_of_record.year-2, 1, 1), is_eligibility_determined: true, effective_ending_on: nil) }
  let!(:tax_household2) { FactoryGirl.create(:tax_household, household: household, effective_starting_on: Date.new(TimeKeeper.date_of_record.year-2, 11, 1), is_eligibility_determined: true, effective_ending_on: nil) }
  let!(:tax_household3) { FactoryGirl.create(:tax_household, household: household, effective_starting_on: Date.new(TimeKeeper.date_of_record.year-2, 6, 1), is_eligibility_determined: true, effective_ending_on: nil) }
  let!(:tax_household4) { FactoryGirl.create(:tax_household, household: household, effective_starting_on: Date.new(TimeKeeper.date_of_record.year-1, 7, 1), created_at: "2018-01-15 21:53:54 UTC", is_eligibility_determined: true, effective_ending_on: nil) }
  let!(:tax_household5) { FactoryGirl.create(:tax_household, household: household, effective_starting_on: Date.new(TimeKeeper.date_of_record.year-1, 4, 1), is_eligibility_determined: true, effective_ending_on: nil) }
  let!(:tax_household6) { FactoryGirl.create(:tax_household, household: household, effective_starting_on: Date.new(TimeKeeper.date_of_record.year-1, 8, 1), created_at: "2018-01-15 21:53:50 UTC", is_eligibility_determined: true, effective_ending_on: nil) }
  let!(:tax_household7) { FactoryGirl.create(:tax_household, household: household, effective_starting_on: Date.new(TimeKeeper.date_of_record.year-1, 1, 1), is_eligibility_determined: true, effective_ending_on: nil) }
  let!(:tax_household8) { FactoryGirl.create(:tax_household, household: household, effective_starting_on: Date.new(TimeKeeper.date_of_record.year, 1, 1), is_eligibility_determined: true, effective_ending_on: nil) }
  let!(:tax_household9) { FactoryGirl.create(:tax_household, household: household, effective_starting_on: Date.new(TimeKeeper.date_of_record.year, 1, 15), created_at: "2018-01-15 21:53:54 UTC", submitted_at: "2018-01-16 21:53:52 UTC", is_eligibility_determined: true, effective_ending_on: nil) }
  let!(:tax_household10) { FactoryGirl.create(:tax_household, household: household, effective_starting_on: Date.new(TimeKeeper.date_of_record.year, 1, 15), created_at: "2018-01-15 21:53:55 UTC", submitted_at: "2018-01-15 21:53:52 UTC", is_eligibility_determined: true, effective_ending_on: nil) }
  let!(:tax_household11) { FactoryGirl.create(:tax_household, household: household, effective_starting_on: Date.new(TimeKeeper.date_of_record.year, 1, 5), is_eligibility_determined: true, effective_ending_on: nil) }


  it "should have only one active tax household for year 2018" do
    household.end_multiple_thh
    expect(household.tax_households.tax_household_with_year(TimeKeeper.date_of_record.year).active_tax_household.count).to be 1
  end

  it "should have only one active tax household for year 2017" do
    household.end_multiple_thh
    expect(household.tax_households.tax_household_with_year(TimeKeeper.date_of_record.year-1).active_tax_household.count).to be 1
  end

  it "should have only one active tax household for year 2016" do
    household.end_multiple_thh
    expect(household.tax_households.tax_household_with_year(TimeKeeper.date_of_record.year-2).active_tax_household.count).to be 1
  end

  it "should be the latest one in the year 2018" do
    latest_active_thh = household.latest_active_thh_with_year(TimeKeeper.date_of_record.year)
    expect(latest_active_thh).to be tax_household11
    household.end_multiple_thh
    latest_active_thh = household.latest_active_thh_with_year(TimeKeeper.date_of_record.year)
    expect(latest_active_thh).to be tax_household11
  end

  it "should be the latest one in the year 2017" do
    latest_active_thh = household.latest_active_thh_with_year(TimeKeeper.date_of_record.year-1)
    expect(latest_active_thh).to be tax_household7
    household.end_multiple_thh
    latest_active_thh = household.latest_active_thh_with_year(TimeKeeper.date_of_record.year-1)
    expect(latest_active_thh).to be tax_household7
  end

end

describe "financial assistance eligibiltiy for a family", type: :model, dbclean: :after_each do
  let!(:person) { FactoryGirl.create(:person, :with_family) }
  let!(:active_household) { person.primary_family.active_household }
  let!(:date) { Date.new(TimeKeeper.date_of_record.year, 1, 1) }
  let!(:hbx_profile) { FactoryGirl.create(:hbx_profile, :open_enrollment_coverage_period) }
  let!(:slcsp) { HbxProfile.current_hbx.benefit_sponsorship.current_benefit_coverage_period.slcsp_id }

  it "should create one active tax household for the specified year" do
    expect(active_household.tax_households.count).to be 0
    active_household.build_thh_and_eligibility(60, 94, date, slcsp)
    expect(active_household.tax_households.count).to be 1
  end

  it "should create one eligibility determination for respective tax household" do
    active_household.build_thh_and_eligibility(200, 73, date, slcsp)
    expect(active_household.latest_active_thh.eligibility_determinations.count).to be 1
  end

  it "end dates all prior THH for the given year" do
    2.times {active_household.build_thh_and_eligibility(200, 73, date, slcsp)}
    expect(active_household.active_thh_with_year(TimeKeeper.date_of_record.year).count).to be 1
  end

end