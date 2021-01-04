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
    let(:consumer_role) {FactoryBot.create(:consumer_role)}
    let(:person) { double(primary_family: family)}
    let(:family) { FactoryBot.create(:family, :with_primary_family_member) }
    let!(:hbx_profile) { FactoryBot.create(:hbx_profile) }
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
        family:family,
        coverage_household: coverage_household,
        benefit_package: benefit_package,
        qle: false
      )
    end
  end

  context "latest_active_tax_household_with_year" do
    let(:family) {FactoryBot.create(:family, :with_primary_family_member)}
    let!(:household) {FactoryBot.create(:household, family: family)}
    let(:tax_household) {FactoryBot.create(:tax_household, household: household, effective_ending_on: nil)}
    let(:tax_household2) {FactoryBot.create(:tax_household, household: household)}
    let!(:hbx1) {FactoryBot.create(:hbx_enrollment, household: household, family: family, is_active: true, aasm_state: 'coverage_enrolled', changing: false, effective_on: (TimeKeeper.date_of_record.beginning_of_month + 10.days))}

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
    let(:family) {FactoryBot.create(:family, :with_primary_family_member)}
    let(:household) {FactoryBot.create(:household, family: family)}
    let!(:hbx1) {FactoryBot.create(:hbx_enrollment, family: family, household: household, is_active: true, aasm_state: 'coverage_enrolled', changing: false, effective_on: (TimeKeeper.date_of_record.beginning_of_month + 10.days), applied_aptc_amount: 10)}
    let!(:hbx2) {FactoryBot.create(:hbx_enrollment, family: family, household: household, is_active: false)}
    let!(:hbx3) {FactoryBot.create(:hbx_enrollment, family: family, household: household, is_active: true, aasm_state: 'coverage_terminated', changing: false, effective_on: (TimeKeeper.date_of_record.beginning_of_month + 10.days))}
    let!(:hbx4) {FactoryBot.create(:hbx_enrollment, family: family, household: household, is_active: true, aasm_state: 'coverage_enrolled', changing: true)}

    it "should return right hbx_enrollments" do
      household.reload
      expect(household.hbx_enrollments.count).to eq 4
      expect(household.hbx_enrollments_with_aptc_by_year(TimeKeeper.date_of_record.year)).to eq [hbx1]
    end
  end

  context "enrolled_including_waived_hbx_enrollments" do
    let(:family) {FactoryBot.create(:family, :with_primary_family_member)}
    let(:household) {FactoryBot.create(:household, family: family)}
    let(:plan1){ FactoryBot.create(:plan_template, :shop_health) }
    let(:plan2){ FactoryBot.create(:plan_template, :shop_dental) }

    context "for shop health enrollment" do
      let!(:hbx1) {FactoryBot.create(:hbx_enrollment, household: household, family: family, plan: plan1, is_active: true, aasm_state: 'coverage_selected', changing: false, effective_on: (TimeKeeper.date_of_record.beginning_of_month + 10.days), applied_aptc_amount: 10)}

      it "should return only health hbx enrollment" do
        expect(household.enrolled_including_waived_hbx_enrollments.size).to eq 1
        expect(household.enrolled_including_waived_hbx_enrollments.to_a).to eq [hbx1]
        expect(household.enrolled_including_waived_hbx_enrollments.map(&:plan).map(&:coverage_kind)).to eq ["health"]
      end
    end

    context "for shop dental enrollment" do
      let!(:hbx2) {FactoryBot.create(:hbx_enrollment, household: household, plan: plan2, family: family,is_active: true, aasm_state: 'coverage_selected', changing: false, effective_on: (TimeKeeper.date_of_record.beginning_of_month + 10.days), applied_aptc_amount: 10)}

      it "should return only health hbx enrollment" do
        expect(household.enrolled_including_waived_hbx_enrollments.size).to eq 1
        expect(household.enrolled_including_waived_hbx_enrollments.to_a).to eq [hbx2]
        expect(household.enrolled_including_waived_hbx_enrollments.map(&:plan).map(&:coverage_kind)).to eq ["dental"]
      end
    end

    context "for both shop health and dental enrollment" do
      let!(:hbx1) {FactoryBot.create(:hbx_enrollment, household: household, plan: plan1, family: family, is_active: true, aasm_state: 'coverage_selected', changing: false, coverage_kind: 'dental', effective_on: (TimeKeeper.date_of_record.beginning_of_month + 10.days), applied_aptc_amount: 10)}
      let!(:hbx3) {FactoryBot.create(:hbx_enrollment, household: household, plan: plan1, family: family, is_active: true, aasm_state: 'coverage_selected', changing: false, coverage_kind: 'dental', effective_on: (TimeKeeper.date_of_record.beginning_of_month + 10.days), applied_aptc_amount: 10)}
      let!(:hbx2) {FactoryBot.create(:hbx_enrollment, household: household, plan: plan2, family: family, is_active: true, aasm_state: 'inactive', changing: false, effective_on: (TimeKeeper.date_of_record.beginning_of_month + 10.days), applied_aptc_amount: 10)}
      let!(:hbx4) {FactoryBot.create(:hbx_enrollment, household: household, plan: plan2, family: family, is_active: true, aasm_state: 'inactive', changing: false, effective_on: (TimeKeeper.date_of_record.beginning_of_month + 10.days), applied_aptc_amount: 10)}
      let!(:hbx5) {FactoryBot.create(:hbx_enrollment, household: household, plan: plan2, family: family, is_active: true, aasm_state: 'coverage_enrolled', changing: false, effective_on: (TimeKeeper.date_of_record.beginning_of_month + 10.days), applied_aptc_amount: 10)}

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
    #let!(:tax_household1) {FactoryBot.create(:tax_household }
    let(:year) { TimeKeeper.date_of_record.year }
    let(:family) {FactoryBot.create(:family, :with_primary_family_member)}
    let!(:household) {FactoryBot.create(:household, family: family)}
    let(:tax_household1) {FactoryBot.create(:tax_household, household: household)}
    let(:tax_household2) {FactoryBot.create(:tax_household, household: household)}
    let(:tax_household3) {FactoryBot.create(:tax_household, household: household)}
    let(:eligibility_determination1) {FactoryBot.create(:eligibility_determination, tax_household: tax_household1)}
    let(:eligibility_determination2) {FactoryBot.create(:eligibility_determination, tax_household: tax_household2)}
    let(:eligibility_determination3) {FactoryBot.create(:eligibility_determination, tax_household: tax_household3)}

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
  let(:family) { FactoryBot.create(:family, :with_primary_family_member, person: person) }
  let(:person) do
    p = FactoryBot.build(:person)
    p.person_relationships.build(relative: person_two, kind: "domestic_partner")
    p.save
    p
  end
  let(:person_two)  { FactoryBot.create(:person)}
  let(:family_member) { FactoryBot.create(:family_member, family: family, person: person_two)}
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
  let!(:person) { FactoryBot.create(:person, :with_family) }
  let!(:household) { person.primary_family.households.first }
  let!(:tax_household1) { FactoryBot.create(:tax_household, household: household, effective_starting_on: Date.new(TimeKeeper.date_of_record.year-2, 1, 1), is_eligibility_determined: true, effective_ending_on: nil) }
  let!(:tax_household2) { FactoryBot.create(:tax_household, household: household, effective_starting_on: Date.new(TimeKeeper.date_of_record.year-2, 11, 1), is_eligibility_determined: true, effective_ending_on: nil) }
  let!(:tax_household3) { FactoryBot.create(:tax_household, household: household, effective_starting_on: Date.new(TimeKeeper.date_of_record.year-2, 6, 1), is_eligibility_determined: true, effective_ending_on: nil) }
  let!(:tax_household4) { FactoryBot.create(:tax_household, household: household, effective_starting_on: Date.new(TimeKeeper.date_of_record.year-1, 7, 1), created_at: "2018-01-15 21:53:54 UTC", is_eligibility_determined: true, effective_ending_on: nil) }
  let!(:tax_household5) { FactoryBot.create(:tax_household, household: household, effective_starting_on: Date.new(TimeKeeper.date_of_record.year-1, 4, 1), is_eligibility_determined: true, effective_ending_on: nil) }
  let!(:tax_household6) { FactoryBot.create(:tax_household, household: household, effective_starting_on: Date.new(TimeKeeper.date_of_record.year-1, 8, 1), created_at: "2018-01-15 21:53:50 UTC", is_eligibility_determined: true, effective_ending_on: nil) }
  let!(:tax_household7) { FactoryBot.create(:tax_household, household: household, effective_starting_on: Date.new(TimeKeeper.date_of_record.year-1, 1, 1), is_eligibility_determined: true, effective_ending_on: nil) }
  let!(:tax_household8) { FactoryBot.create(:tax_household, household: household, effective_starting_on: Date.new(TimeKeeper.date_of_record.year, 1, 1), is_eligibility_determined: true, effective_ending_on: nil) }
  let!(:tax_household9) { FactoryBot.create(:tax_household, household: household, effective_starting_on: Date.new(TimeKeeper.date_of_record.year, 1, 15), created_at: "2018-01-15 21:53:54 UTC", submitted_at: "2018-01-16 21:53:52 UTC", is_eligibility_determined: true, effective_ending_on: nil) }
  let!(:tax_household10) { FactoryBot.create(:tax_household, household: household, effective_starting_on: Date.new(TimeKeeper.date_of_record.year, 1, 15), created_at: "2018-01-15 21:53:55 UTC", submitted_at: "2018-01-15 21:53:52 UTC", is_eligibility_determined: true, effective_ending_on: nil) }
  let!(:tax_household11) { FactoryBot.create(:tax_household, household: household, effective_starting_on: Date.new(TimeKeeper.date_of_record.year, 1, 5), is_eligibility_determined: true, effective_ending_on: nil) }


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
  let!(:person) { FactoryBot.create(:person, :with_family) }
  let!(:active_household) { person.primary_family.active_household }
  let!(:date) { Date.new(TimeKeeper.date_of_record.year, 1, 1) }
  let!(:hbx_profile) { FactoryBot.create(:hbx_profile, :open_enrollment_coverage_period) }
  let!(:slcsp) { HbxProfile.current_hbx.benefit_sponsorship.current_benefit_coverage_period.slcsp_id }

  context 'for one active tax household' do
    before do
      active_household.build_thh_and_eligibility(60, 94, date, slcsp, 'Renewals')
    end

    it 'should create one active tax household for the specified year' do
      expect(active_household.tax_households.count).to be 1
    end

    it 'should create ED with source Renewals' do
      expect(active_household.tax_households.first.latest_eligibility_determination.source).to eq('Renewals')
    end
  end

  context 'create one ED' do
    before do
      active_household.build_thh_and_eligibility(200, 73, date, slcsp, 'Admin')
      @eligibility_determination = active_household.latest_active_thh.latest_eligibility_determination
    end

    it "should create one eligibility determination for respective tax household" do
      expect(active_household.latest_active_thh.eligibility_determinations.count).to be 1
    end

    it 'should create ED with source Admin' do
      expect(@eligibility_determination.source).to eq('Admin')
    end
  end

  context 'end date duplicate THH' do
    before :each do
      2.times {active_household.build_thh_and_eligibility(200, 73, date, slcsp, 'Renewals')}
      @ed = active_household.latest_active_thh.latest_eligibility_determination
    end

    it 'end dates all prior THH for the given year' do
      expect(active_household.active_thh_with_year(TimeKeeper.date_of_record.year).count).to be 1
    end

    it 'should have Renewals as source' do
      expect(@ed.source).to eq('Renewals')
    end
  end

  context 'for limited csr determination' do
    before do
      active_household.build_thh_and_eligibility(200, 'limited', date, slcsp, 'Admin')
      @eligibility_determination = active_household.latest_active_thh.latest_eligibility_determination
    end

    it 'should create determination with limited csr' do
      expect(@eligibility_determination.csr_eligibility_kind).to eq('csr_limited')
    end

    it 'should create determination with csr_percent_as_integer as -1' do
      expect(@eligibility_determination.csr_percent_as_integer).to eq(-1)
    end
  end
end

describe Household, "for creating a new taxhousehold using create eligibility", type: :model, dbclean: :after_each do
  let!(:person100)      { FactoryBot.create(:person, :with_consumer_role, :with_active_consumer_role) }
  let!(:family100)      { FactoryBot.create(:family, :with_primary_family_member, person: person100) }
  let(:household100)    { family100.active_household }
  let!(:hbx_profile100) { FactoryBot.create(:hbx_profile) }
  let(:current_date)    { TimeKeeper.date_of_record }
  let(:params)        {
                        {"person_id"=> person100.id.to_s,
                          "family_actions_id"=>"family_actions_#{family100.id.to_s}",
                          "max_aptc"=>"100.00",
                          "csr"=>"94",
                          "effective_date"=> "#{current_date.year}-#{current_date.month}-#{current_date.day}",
                          "family_members"=>
                            { family100.primary_applicant.person.hbx_id => {"pdc_type"=>"is_ia_eligible", "reason"=>"7hvgds"} }
                        }
                      }

  context "create_new_tax_household" do
    before :each do
      params.merge!({'csr' => 'limited'})
      household100.create_new_tax_household(params)
      @determination = household100.tax_households.active_tax_household.first.latest_eligibility_determination
    end

    it "should create new tax_household instance" do
      expect(household100.tax_households).not_to be []
    end

    it "should create new tax_household_member instance" do
      expect(household100.tax_households[0].tax_household_members).not_to be []
    end

    it "should create new eligibility_determination instance" do
      expect(household100.tax_households[0].eligibility_determinations).not_to be []
    end

    it 'should match with expected csr percent' do
      expect(@determination.csr_percent_as_integer).to eq(-1)
    end

    it 'should match with expected csr eligibility kind' do
      expect(@determination.csr_eligibility_kind).to eq('csr_limited')
    end
  end

  context 'for apply_aggregate_to_enrollment' do
    let(:product) {FactoryBot.create(:benefit_markets_products_health_products_health_product, :silver)}
    let!(:current_enr) do
      enr = FactoryBot.create(:hbx_enrollment,
                              :individual_assisted,
                              coverage_kind: 'health',
                              household: household100,
                              family: family100,
                              effective_on: TimeKeeper.date_of_record.beginning_of_year,
                              product: product,
                              consumer_role_id: person100.consumer_role.id)
      FactoryBot.create(:hbx_enrollment_member, applicant_id: family100.primary_applicant.id, hbx_enrollment: enr)
      enr
    end

    before do
      allow(::BenefitMarkets::Products::ProductRateCache).to receive(:lookup_rate) {|_id, _start, age| age * 1.0}
      year = TimeKeeper.date_of_record.year
      allow(TimeKeeper).to receive(:date_of_record).and_return(Date.new(year, 8, 4))
      HbxProfile.current_hbx.benefit_sponsorship.benefit_coverage_periods.detect {|bcp| bcp.contains?(TimeKeeper.datetime_of_record)}.update_attributes!(slcsp_id: current_enr.product.id)
      household100.create_new_tax_household(params.merge({'max_aptc' => '1000.00'}))
      @new_enr = family100.reload.hbx_enrollments.last
    end

    it 'expect to auto generate enrollment' do
      if EnrollRegistry.feature_enabled?(:apply_aggregate_to_enrollment)
        expect(@new_enr.applied_aptc_amount.to_f).not_to eq(0.00)
        expect(@new_enr.id).not_to eq(current_enr.id)
      end
    end
  end
end
