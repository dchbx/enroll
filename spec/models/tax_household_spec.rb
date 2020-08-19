require 'rails_helper'
RSpec.describe TaxHousehold, type: :model do
  let(:family)  { FactoryGirl.create(:family, :with_primary_family_member) }
  let!(:plan)   { FactoryGirl.create(:plan, active_year: 2019, hios_id: '86052DC0400001-01')}
  let(:current_date)  { TimeKeeper.date_of_record }

  before :each do
    allow_any_instance_of(FinancialAssistance::Application).to receive(:set_benchmark_plan_id)
  end

  context '.include document matchers' do
    it { is_expected.to be_mongoid_document }
  end

  context '.modelFeilds' do
    it { is_expected.to have_field(:application_id).of_type(BSON::ObjectId) }
    it { is_expected.to have_field(:hbx_assigned_id).of_type(Integer) }
    it { is_expected.to have_field(:allocated_aptc).of_type(Money).with_default_value_of(0.00) }
    it { is_expected.to have_field(:is_eligibility_determined).of_type(Mongoid::Boolean).with_default_value_of(false) }
    it { is_expected.to have_field(:effective_starting_on).of_type(Date) }
    it { is_expected.to have_field(:effective_ending_on).of_type(Date) }
    it { is_expected.to have_field(:submitted_at).of_type(DateTime) }
  end

  context '.associations' do
    it 'embeded in household' do
      assc = described_class.reflect_on_association(:household)
      expect(assc.macro).to eq :embedded_in
    end
    it 'embeded many tax_household_members' do
      assc = described_class.reflect_on_association(:tax_household_members)
      expect(assc.macro).to eq :embeds_many
    end
    it 'embeds many household' do
      assc = described_class.reflect_on_association(:eligibility_determinations)
      expect(assc.macro).to eq :embeds_many
    end
  end

  context '.accept_nested_attributes_for' do
    it { is_expected.to accept_nested_attributes_for(:tax_household_members) }
  end

  describe 'single tax household' do
    context 'aptc_ratio_by_member' do
      let!(:plan) { FactoryGirl.build(:plan, :with_premium_tables) }
      let(:current_hbx) { double(benefit_sponsorship: double(benefit_coverage_periods: [benefit_coverage_period])) }
      let(:benefit_coverage_period) { double(contains?: true, second_lowest_cost_silver_plan: plan) }
      let(:household) { family.active_household }
      let(:application) { FactoryGirl.create(:application, family: family) }
      let(:tax_household) { FactoryGirl.create(:tax_household, effective_starting_on: current_date, household: household, application_id: application.id) }
      let(:family_member1) { FactoryGirl.create(:family_member, family: family) }
      let(:family_member2) { FactoryGirl.create(:family_member, family: family) }
      let(:applicant1) { FactoryGirl.create(:applicant, application: application, tax_household_id: tax_household.id, family_member_id: family_member1.id) }
      let(:applicant2) { FactoryGirl.create(:applicant, application: application, tax_household_id: tax_household.id, family_member_id: family_member2.id) }

      before :each do
        allow(HbxProfile).to receive(:current_hbx).and_return(current_hbx)
        allow(current_hbx).to receive(:under_open_enrollment?).and_return(false)
        allow(plan).to receive(:premium_for).and_return(110)
      end

      it 'can return ratio hash' do
        allow(tax_household).to receive(:aptc_members).and_return([applicant1, applicant2])
        expect(tax_household.aptc_ratio_by_member.class).to eq Hash
        result = {family_member1.id.to_s => 0.5, family_member2.id.to_s => 0.5}
        expect(tax_household.aptc_ratio_by_member).to eq result
      end
      it 'should return 1.0 ratio for first family member as second family member is eligible for medicaid' do
        applicant2.update_attributes(:is_totally_ineligible => true, is_ia_eligible: false)
        allow(tax_household).to receive(:aptc_members).and_return([applicant1])
        expect(tax_household.aptc_ratio_by_member.class).to eq Hash
        result = {family_member1.id.to_s => 1.0}
        expect(tax_household.aptc_ratio_by_member).to eq result
      end
    end

    context 'aptc_available_amount_by_member' do
      let(:aptc_ratio_by_member) { {'member1' => 0.6, 'member2' => 0.4} }
      let(:hbx_member1) { double(applicant_id: 'member1', applied_aptc_amount: 20) }
      let(:hbx_member2) { double(applicant_id: 'member2', applied_aptc_amount: 10) }
      let(:hbx_enrollment) { double(applied_aptc_amount: 30, hbx_enrollment_members: [hbx_member1, hbx_member2]) }
      let(:household) { family.active_household }
      let(:application) { double(family: family) }

      it 'can return result' do
        tax_household = TaxHousehold.new(household: household)
        allow(tax_household).to receive(:family).and_return family
        allow(family).to receive(:active_household).and_return household
        allow(tax_household).to receive(:application).and_return application
        allow(tax_household).to receive(:aptc_ratio_by_member).and_return aptc_ratio_by_member
        allow(tax_household).to receive(:current_max_aptc).and_return 100
        allow(tax_household).to receive(:effective_starting_on).and_return current_date
        allow(household).to receive(:hbx_enrollments_with_aptc_by_year).and_return([hbx_enrollment])
        expect(tax_household.aptc_available_amount_by_member.class).to eq Hash
        result = {'member1' => 40, 'member2' => 30}
        expect(tax_household.aptc_available_amount_by_member).to eq result
      end
    end

    context 'aptc_available_amount_for_enrollment' do
      let(:aptc_available_amount_by_member) { {'member1' => 60, 'member2' => 40} }
      let(:hbx_member1) { double(applicant_id: 'member1') }
      let(:hbx_member2) { double(applicant_id: 'member2') }
      let(:hbx_enrollment) { double(applied_aptc_amount: 30, hbx_enrollment_members: [hbx_member1, hbx_member2]) }
      let(:household) { double }
      let!(:plan) {FactoryGirl.build(:plan, :with_premium_tables)}
      let(:decorated_plan) {double}

      before :each do
        @tax_household = TaxHousehold.new
        allow(plan).to receive(:ehb).and_return 0.9
        allow(@tax_household).to receive(:aptc_available_amount_by_member).and_return aptc_available_amount_by_member
        allow(@tax_household).to receive(:total_aptc_available_amount_for_enrollment).and_return 100
        allow(UnassistedPlanCostDecorator).to receive(:new).and_return(decorated_plan)
        allow(decorated_plan).to receive(:premium_for).and_return(100)
        allow(household).to receive(:hbx_enrollments_with_aptc_by_date).and_return([hbx_enrollment])
      end

      it 'can return result when plan is individual' do
        allow(plan).to receive(:coverage_kind).and_return 'individual'
        expect(@tax_household.aptc_available_amount_for_enrollment(hbx_enrollment, plan, 50).class).to eq Hash
        result = {'member1' => 30, 'member2' => 20}
        expect(@tax_household.aptc_available_amount_for_enrollment(hbx_enrollment, plan, 50)).to eq result
      end
      it 'when ehb_premium > aptc_amount' do
        allow(decorated_plan).to receive(:premium_for).and_return(10)
        allow(plan).to receive(:coverage_kind).and_return 'individual'
        expect(@tax_household.aptc_available_amount_for_enrollment(hbx_enrollment, plan, 50).class).to eq Hash
        result = {'member1' => 9, 'member2' => 9}
        expect(@tax_household.aptc_available_amount_for_enrollment(hbx_enrollment, plan, 50)).to eq result
      end
      it 'can return result when plan is dental' do
        allow(plan).to receive(:coverage_kind).and_return 'dental'
        expect(@tax_household.aptc_available_amount_for_enrollment(hbx_enrollment, plan, 50).class).to eq Hash
        result = {'member1' => 0, 'member2' => 0}
        expect(@tax_household.aptc_available_amount_for_enrollment(hbx_enrollment, plan, 50)).to eq result
      end
      it 'can return result when total_aptc_available_amount is 0' do
        allow(@tax_household).to receive(:total_aptc_available_amount_for_enrollment).and_return 0
        allow(decorated_plan).to receive(:premium_for).and_return(10)
        allow(plan).to receive(:coverage_kind).and_return 'individual'
        expect(@tax_household.aptc_available_amount_for_enrollment(hbx_enrollment, plan, 50).class).to eq Hash
        result = {'member1' => 0, 'member2' => 0}
        expect(@tax_household.aptc_available_amount_for_enrollment(hbx_enrollment, plan, 50)).to eq result
      end
    end

    context 'current_max_aptc' do
      before :each do
        @tax_household = TaxHousehold.new(effective_starting_on: current_date)
      end

      it 'return max aptc when in the same year' do
        allow(@tax_household).to receive(:preferred_eligibility_determination).and_return(double(determined_on: current_date, max_aptc: 100))
        expect(@tax_household.current_max_aptc).to eq 100
      end
      it 'return 0 when not in the same year' do
        allow(@tax_household).to receive(:preferred_eligibility_determination).and_return(double(determined_on: current_date + 1.year, max_aptc: 0))
        expect(@tax_household.current_max_aptc).to eq 0
      end
    end

    context 'current_csr_eligibility_kind' do
      let(:household) { family.active_household }
      let(:application) {FactoryGirl.create(:application, family: family)}
      let(:tax_household) {FactoryGirl.create(:tax_household, household: household, application_id: application.id)}
      let(:eligibility_determination) {FactoryGirl.create(:eligibility_determination, csr_eligibility_kind: 'csr_87', determined_on: current_date, tax_household: tax_household)}

      it 'should equal to the csr_eligibility_kind of preferred_eligibility_determination' do
        eligibility_determination.save!
        expect(application.current_csr_eligibility_kind(tax_household.id)).to eq eligibility_determination.csr_eligibility_kind
      end
      it 'should return the right eligibility_determination based on the tax_household_id' do
        eligibility_determination.save!
        ed = tax_household.eligibility_determinations.first
        expect(ed).to eq eligibility_determination
      end
    end
  end

  describe 'multi tax households' do
    let!(:family)  { FactoryGirl.create(:family, :with_primary_family_member) }
    let!(:family_member1) { family.primary_applicant }
    let!(:family_member2) { FactoryGirl.create(:family_member, family: family) }
    let!(:family_member3) { FactoryGirl.create(:family_member, family: family) }
    let!(:family_member4) { FactoryGirl.create(:family_member, family: family) }
    let!(:application) { FactoryGirl.create(:application, family: family) }
    let!(:household1) { FactoryGirl.create(:household, family: family) }
    let!(:tax_household1) { FactoryGirl.create(:tax_household, household: household1, effective_starting_on: current_date, application_id: application.id) }
    let!(:tax_household2) { FactoryGirl.create(:tax_household, household: household1, effective_starting_on: current_date, application_id: application.id) }
    let!(:eligibility_determination1) { FactoryGirl.create(:eligibility_determination,  tax_household: tax_household1, source: 'Curam', csr_eligibility_kind: 'csr_87', determined_on: current_date, max_aptc: 200.00) }
    let!(:eligibility_determination2) { FactoryGirl.create(:eligibility_determination, tax_household: tax_household1, source: 'Haven', csr_eligibility_kind: 'csr_94', determined_on: current_date, max_aptc: 200.00) }
    let!(:eligibility_determination3) { FactoryGirl.create(:eligibility_determination, tax_household: tax_household2, source: 'Curam', csr_eligibility_kind: 'csr_73', determined_on: current_date, max_aptc: 200.00) }
    let!(:eligibility_determination4) { FactoryGirl.create(:eligibility_determination, tax_household: tax_household2, source: 'Haven', csr_eligibility_kind: 'csr_100', determined_on: current_date, max_aptc: 200.00) }
    let!(:applicant1) { FactoryGirl.create(:applicant, tax_household_id: tax_household1.id, application: application, family_member_id: family_member1.id) }
    let!(:applicant2) { FactoryGirl.create(:applicant, tax_household_id: tax_household1.id, application: application, family_member_id: family_member2.id) }
    let!(:applicant3) { FactoryGirl.create(:applicant, tax_household_id: tax_household2.id, application: application, family_member_id: family_member3.id) }
    let!(:applicant4) { FactoryGirl.create(:applicant, tax_household_id: tax_household2.id, application: application, family_member_id: family_member4.id) }

    context 'aptc_ratio_by_member' do
      let!(:plan) {FactoryGirl.build(:plan, :with_premium_tables)}
      let(:current_hbx) {double(benefit_sponsorship: double(benefit_coverage_periods: [benefit_coverage_period]))}
      let(:benefit_coverage_period) {double(contains?: true, second_lowest_cost_silver_plan: plan)}

      before :each do
        allow(HbxProfile).to receive(:current_hbx).and_return(current_hbx)
        allow(plan).to receive(:premium_for).and_return(110)
        allow(tax_household1).to receive(:aptc_members).and_return([applicant1, applicant2])
        allow(tax_household2).to receive(:aptc_members).and_return([applicant3, applicant4])
      end

      it 'can return ratio hash' do
        expect(tax_household1.aptc_ratio_by_member.class).to eq Hash
        result1 = {family_member1.id.to_s => 0.5, family_member2.id.to_s => 0.5}
        expect(tax_household1.aptc_ratio_by_member).to eq result1
        expect(tax_household2.aptc_ratio_by_member.class).to eq Hash
        result2 = {family_member3.id.to_s => 0.5, family_member4.id.to_s => 0.5}
        expect(tax_household2.aptc_ratio_by_member).to eq result2
      end
      it 'should return 1.0 ratio for first family member in both tax households' do
        applicant2.update_attributes(:is_medicaid_chip_eligible => true)
        allow(tax_household1).to receive(:aptc_members).and_return([applicant1])
        applicant4.update_attributes(:is_without_assistance => true)
        allow(tax_household2).to receive(:aptc_members).and_return([applicant3])
        expect(tax_household1.aptc_ratio_by_member.class).to eq Hash
        result1 = {family_member1.id.to_s => 1.0}
        expect(tax_household1.aptc_ratio_by_member).to eq result1
        expect(tax_household2.aptc_ratio_by_member.class).to eq Hash
        result2 = {family_member3.id.to_s => 1.0}
        expect(tax_household2.aptc_ratio_by_member).to eq result2
      end
    end

    context 'aptc_available_amount_by_member' do
      let(:aptc_ratio_by_member1) { {family_member1.id.to_s => 0.5, family_member2.id.to_s => 0.5} }
      let(:aptc_ratio_by_member2) { {family_member3.id.to_s => 0.5, family_member4.id.to_s => 0.5} }
      let!(:hbx_member1) { double(applicant_id: family_member1.id, applied_aptc_amount: 70) }
      let!(:hbx_member2) { double(applicant_id: family_member3.id, applied_aptc_amount: 50) }
      let!(:hbx_enrollment) { double(applied_aptc_amount: 30, hbx_enrollment_members: [hbx_member1, hbx_member2]) }
      let!(:household) { double }

      it 'can return result' do
        allow(tax_household1).to receive(:family).and_return family
        allow(family).to receive(:active_household).and_return household
        allow(tax_household1).to receive(:application).and_return application
        allow(tax_household1).to receive(:aptc_ratio_by_member).and_return aptc_ratio_by_member1
        allow(tax_household1).to receive(:effective_starting_on).and_return current_date
        allow(tax_household2).to receive(:family).and_return family
        allow(tax_household2).to receive(:application).and_return application
        allow(tax_household2).to receive(:aptc_ratio_by_member).and_return aptc_ratio_by_member2
        allow(tax_household2).to receive(:effective_starting_on).and_return current_date
        allow(household).to receive(:hbx_enrollments_with_aptc_by_year).and_return([hbx_enrollment])
        expect(tax_household1.aptc_available_amount_by_member.class).to eq Hash
        result1 = {family_member1.id.to_s => 100.0, family_member2.id.to_s => 100.0}
        expect(tax_household1.aptc_available_amount_by_member).to eq result1
        expect(tax_household2.aptc_available_amount_by_member.class).to eq Hash
        result2 = {family_member3.id.to_s => 100.0, family_member4.id.to_s => 100.0}
        expect(tax_household2.aptc_available_amount_by_member).to eq result2
      end
    end

    context 'aptc_available_amount_for_enrollment' do
      let!(:aptc_available_amount_by_member1) { {family_member1.id.to_s => 100.0, family_member2.id.to_s => 100.0} }
      let!(:aptc_available_amount_by_member2) { {family_member3.id.to_s => 100.0, family_member4.id.to_s => 100.0} }
      let!(:hbx_member1) { double(applicant_id: family_member1.id) }
      let!(:hbx_member2) { double(applicant_id: family_member3.id) }
      let!(:hbx_enrollment) { double(applied_aptc_amount: 30, hbx_enrollment_members: [hbx_member1, hbx_member2]) }
      let!(:household) { double }
      let!(:plan) {FactoryGirl.build(:plan, :with_premium_tables)}
      let!(:decorated_plan) {double}

      before :each do
        allow(plan).to receive(:ehb).and_return 0.9
        allow(tax_household1).to receive(:aptc_available_amount_by_member).and_return aptc_available_amount_by_member1
        allow(tax_household1).to receive(:total_aptc_available_amount_for_enrollment).and_return tax_household1.current_max_aptc
        allow(tax_household2).to receive(:aptc_available_amount_by_member).and_return aptc_available_amount_by_member2
        allow(tax_household2).to receive(:total_aptc_available_amount_for_enrollment).and_return tax_household2.current_max_aptc
        allow(UnassistedPlanCostDecorator).to receive(:new).and_return(decorated_plan)
        allow(decorated_plan).to receive(:premium_for).and_return(100)
        allow(household).to receive(:hbx_enrollments_with_aptc_by_date).and_return([hbx_enrollment])
      end

      it 'can return result when plan is individual' do
        allow(plan).to receive(:coverage_kind).and_return 'individual'
        expect(tax_household1.aptc_available_amount_for_enrollment(hbx_enrollment, plan, 100).class).to eq Hash
        result1 = {family_member1.id.to_s => 50.0, family_member3.id.to_s => 0.0}
        expect(tax_household1.aptc_available_amount_for_enrollment(hbx_enrollment, plan, 100)).to eq result1
        expect(tax_household2.aptc_available_amount_for_enrollment(hbx_enrollment, plan, 100).class).to eq Hash
        result2 = {family_member1.id.to_s => 0.0, family_member3.id.to_s => 50.0}
        expect(tax_household2.aptc_available_amount_for_enrollment(hbx_enrollment, plan, 100)).to eq result2
      end
      it 'when ehb_premium > aptc_amount' do
        allow(decorated_plan).to receive(:premium_for).and_return(10)
        allow(plan).to receive(:coverage_kind).and_return 'individual'
        expect(tax_household1.aptc_available_amount_for_enrollment(hbx_enrollment, plan, 100).class).to eq Hash
        result1 = {family_member1.id.to_s => 9, family_member3.id.to_s => 0}
        expect(tax_household1.aptc_available_amount_for_enrollment(hbx_enrollment, plan, 100)).to eq result1
        expect(tax_household2.aptc_available_amount_for_enrollment(hbx_enrollment, plan, 100).class).to eq Hash
        result2 = {family_member1.id.to_s => 0, family_member3.id.to_s => 9}
        expect(tax_household2.aptc_available_amount_for_enrollment(hbx_enrollment, plan, 100)).to eq result2
      end
      it 'can return result when plan is dental' do
        allow(plan).to receive(:coverage_kind).and_return 'dental'
        expect(tax_household1.aptc_available_amount_for_enrollment(hbx_enrollment, plan, 100).class).to eq Hash
        result = {family_member1.id.to_s => 0, family_member3.id.to_s => 0}
        expect(tax_household1.aptc_available_amount_for_enrollment(hbx_enrollment, plan, 100)).to eq result
        expect(tax_household2.aptc_available_amount_for_enrollment(hbx_enrollment, plan, 100).class).to eq Hash
        expect(tax_household2.aptc_available_amount_for_enrollment(hbx_enrollment, plan, 100)).to eq result
      end
      it 'can return result when total_aptc_available_amount is 0' do
        allow(tax_household1).to receive(:total_aptc_available_amount_for_enrollment).and_return 0
        allow(tax_household2).to receive(:total_aptc_available_amount_for_enrollment).and_return 0
        allow(decorated_plan).to receive(:premium_for).and_return(10)
        allow(plan).to receive(:coverage_kind).and_return 'individual'
        expect(tax_household1.aptc_available_amount_for_enrollment(hbx_enrollment, plan, 100).class).to eq Hash
        result = {family_member1.id.to_s => 0, family_member3.id.to_s => 0}
        expect(tax_household1.aptc_available_amount_for_enrollment(hbx_enrollment, plan, 100)).to eq result
        expect(tax_household2.aptc_available_amount_for_enrollment(hbx_enrollment, plan, 100).class).to eq Hash
        expect(tax_household2.aptc_available_amount_for_enrollment(hbx_enrollment, plan, 100)).to eq result
      end
    end

    context 'current_max_aptc' do
      it 'return max aptc when in the same year' do
        expect(tax_household1.current_max_aptc).to eq 200
        expect(tax_household2.current_max_aptc).to eq 200
      end
      it 'return 0 when not in the same year' do
        allow(tax_household1).to receive(:preferred_eligibility_determination).and_return(double(determined_on: current_date + 1.year, max_aptc: 0))
        allow(tax_household2).to receive(:preferred_eligibility_determination).and_return(double(determined_on: current_date + 1.year, max_aptc: 0))
        expect(tax_household1.current_max_aptc).to eq 0
        expect(tax_household2.current_max_aptc).to eq 0
      end
    end

    context 'current_csr_eligibility_kind' do

      before :each do
        allow(family).to receive(:active_household).and_return household1
      end

      it 'should equal to the csr_eligibility_kind of preferred_eligibility_determination' do
        expect(application.current_csr_eligibility_kind(tax_household1.id)).to eq tax_household1.preferred_eligibility_determination.csr_eligibility_kind
        expect(application.current_csr_eligibility_kind(tax_household2.id)).to eq tax_household2.preferred_eligibility_determination.csr_eligibility_kind
      end
      it 'should return the right eligibility_determination based on the tax_household_id' do
        ed1 = tax_household1.eligibility_determinations.first
        expect(ed1).to eq eligibility_determination1
        ed2 = tax_household2.eligibility_determinations.first
        expect(ed2).to eq eligibility_determination3
      end
    end
  end

  context 'valid_csr_kind' do
    let(:hbx_member1) { double(applicant_id: 'member1') }
    let(:hbx_member2) { double(applicant_id: 'member2') }
    let(:hbx_enrollment) { double(hbx_enrollment_members: [hbx_member1, hbx_member2]) }
    let(:eligibility_determination) {EligibilityDetermination.new(csr_eligibility_kind: 'csr_100', determined_on: current_date)}
    let(:tax_household_member1) {double(is_ia_eligible?: true, age_on_effective_date: 28, applicant_id: 'tax_member1')}
    let(:tax_household_member2) {double(is_ia_eligible?: true, age_on_effective_date: 26, applicant_id: 'tax_member2')}
    let(:tax_household) {TaxHousehold.new}

    it 'should equal to the csr_kind of latest_eligibility_determination' do
      tax_household.eligibility_determinations = [eligibility_determination]
      expect(tax_household.valid_csr_kind(hbx_enrollment)).to eq eligibility_determination.csr_eligibility_kind
    end
  end

  context 'is_all_non_aptc?' do
    let!(:family) { create(:family, :with_primary_family_member_and_dependent) }
    let(:household) { create(:household, family: family) }
    let!(:tax_household) { create(:tax_household, household: household) }
    let(:hbx_enrollment) { create(:hbx_enrollment, :with_enrollment_members,household: household) }

    context 'when all family_members are medicaid' do
      before do
        allow(tax_household).to receive(:is_all_non_aptc?).and_return false
      end

      it 'should return false' do
        result = tax_household.is_all_non_aptc?(hbx_enrollment)
        expect(result).to eq(false)
      end
    end

    context 'when all family_members are not medicaid' do
      it 'should return true' do
        result = tax_household.is_all_non_aptc?(hbx_enrollment)
        expect(result).to eq(true)
      end
    end
  end

  context 'total_aptc_available_amount_for_enrollment' do
    let!(:family) { create(:family, :with_primary_family_member_and_dependent) }
    let(:household) { create(:household, family: family) }
    let!(:tax_household) { create(:tax_household, household: household) }
    let(:hbx_enrollment) { create(:hbx_enrollment, :with_enrollment_members,household: household) }
    let(:member_ids) { family.active_family_members.collect(&:id) }
    let(:aptc_available_amount_by_member) { { member_ids.first.to_s => 60, member_ids.second.to_s => 40, member_ids.last.to_s => 110 } }
    let(:total_aptc_available_amount) { 210 }

    before :each do
      allow(tax_household).to receive(:aptc_available_amount_by_member).and_return aptc_available_amount_by_member
    end

    context 'when all family members checked' do
      before do
        allow(tax_household).to receive(:unwanted_family_members).and_return []
      end

      context 'when all family_members are medicaid' do
        before do
          allow(tax_household).to receive(:is_all_non_aptc?).and_return false
        end

        it 'should return all members amount' do
          result = tax_household.total_aptc_available_amount_for_enrollment(hbx_enrollment)
          expect(result).to eq(total_aptc_available_amount)
        end
      end

      context 'when all family_members are not medicaid' do
        it 'should return 0' do
          result = tax_household.total_aptc_available_amount_for_enrollment(hbx_enrollment)
          expect(result).to eq(0)
        end
      end
    end

    context 'when family members unchecked' do
      let(:total_benchmark_amount) { 60 }

      before do
        allow(tax_household).to receive(:unwanted_family_members).and_return [member_ids.first.to_s]
        allow(tax_household).to receive(:total_benchmark_amount).and_return total_benchmark_amount
        allow(tax_household).to receive(:is_all_non_aptc?).and_return false
        allow(tax_household).to receive(:find_aptc_family_members).and_return true
      end

      it 'should deduct benchmark cost' do
        result = tax_household.total_aptc_available_amount_for_enrollment(hbx_enrollment)
        expect(result).not_to eq(total_aptc_available_amount)
        expect(result).to eq(total_aptc_available_amount - total_benchmark_amount)
      end
    end
  end

  describe 'total_aptc_available_amount_for_enrollment', dbclean: :after_each do

    context 'for family_members with two aptc eligible and one medicaid' do
      let!(:hbx_profile) { FactoryGirl.create(:hbx_profile, :open_enrollment_coverage_period) }
      let(:plan) { FactoryGirl.create(:plan, :with_premium_tables, market: 'individual', metal_level: 'silver', csr_variant_id: '01', active_year: current_date.year, hios_id: '94506DC0390014-01') }
      let!(:person) { FactoryGirl.create(:person, :with_family) }
      let!(:family) { person.primary_family }
      let!(:family_member1) {FactoryGirl.create(:family_member, family: person.primary_family)}
      let!(:family_member2) {FactoryGirl.create(:family_member, family: person.primary_family)}
      let(:member_ids) { family.active_family_members.collect(&:id) }
      let!(:hbx_enrollment_member1) { FactoryGirl.create(:hbx_enrollment_member, applicant_id: family.family_members.first.id, eligibility_date: current_date, coverage_start_on: current_date, hbx_enrollment: hbx_enrollment)}
      let!(:hbx_enrollment_member2) { FactoryGirl.create(:hbx_enrollment_member, applicant_id: family.family_members.second.id, eligibility_date: current_date, coverage_start_on: current_date, hbx_enrollment: hbx_enrollment)}
      let!(:hbx_enrollment_member3) { FactoryGirl.create(:hbx_enrollment_member, applicant_id: family.family_members.last.id, eligibility_date: current_date, coverage_start_on: current_date, hbx_enrollment: hbx_enrollment)}
      let!(:hbx_enrollment) {FactoryGirl.create(:hbx_enrollment,waiver_reason: nil,kind: 'individual', enrollment_kind: 'special_enrollment', coverage_kind: 'health', submitted_at: current_date - 6.months, household: family.active_household)}
      let!(:tax_household) {FactoryGirl.create(:tax_household, household: family.active_household, created_at: current_date - 5.months)}
      let!(:tax_household_member1) {tax_household.tax_household_members.create!(is_ia_eligible: true, applicant_id: person.primary_family.family_members[0].id)}
      let!(:tax_household_member2) {tax_household.tax_household_members.create!(is_ia_eligible: true, applicant_id: person.primary_family.family_members[1].id)}
      let!(:tax_household_member3) {tax_household.tax_household_members.create!(is_ia_eligible: false, applicant_id: person.primary_family.family_members[2].id)}
      let!(:eligibility_determination) {FactoryGirl.create(:eligibility_determination, max_aptc: 500,  tax_household: tax_household)}

      before do
        hbx_profile.benefit_sponsorship.benefit_coverage_periods.detect {|bcp| bcp.contains?(TimeKeeper.datetime_of_record)}.update_attributes!(slcsp_id: plan.id)
        person.update_attributes!(dob: current_date - 38.years)
        person.primary_family.family_members[1].person.update_attributes!(dob: current_date - 28.years)
        person.primary_family.family_members[2].person.update_attributes!(dob: current_date - 18.years)
      end

      context 'having only one previous non aptc enrollment' do
        context 'when one family_member in plan shopping' do
          let(:shopping_hbx_enrollment_member){ FactoryGirl.build(:hbx_enrollment_member, applicant_id: family.family_members.first.id) }
          let(:shopping_hbx_enrollment){FactoryGirl.build(:hbx_enrollment, aasm_state: 'shopping',hbx_enrollment_members: [shopping_hbx_enrollment_member], household: family.active_household)}

          it 'should return available APTC amount' do
            result = tax_household.total_aptc_available_amount_for_enrollment(shopping_hbx_enrollment)
            expect(result.round(2)).to eq(221.32)
          end
        end

        context 'when two family_members in plan shopping' do

          let(:shopping_hbx_enrollment_member){ FactoryGirl.build(:hbx_enrollment_member, eligibility_date: current_date + 1.month, applicant_id: family.family_members.first.id) }
          let(:shopping_hbx_enrollment_member1){ FactoryGirl.build(:hbx_enrollment_member, eligibility_date: current_date + 1.month, applicant_id: family.family_members.second.id) }
          let(:shopping_hbx_enrollment){FactoryGirl.build(:hbx_enrollment, aasm_state: 'shopping',hbx_enrollment_members: [shopping_hbx_enrollment_member, shopping_hbx_enrollment_member1], household: family.active_household)}

          it 'should return available APTC amount' do
            result = tax_household.total_aptc_available_amount_for_enrollment(shopping_hbx_enrollment)
            expect(result.round(2)).to eq(500.00)
          end
        end

        context 'when all family_members in plan shopping' do

          let(:shopping_hbx_enrollment_member){ FactoryGirl.build(:hbx_enrollment_member, applicant_id: family.family_members.first.id) }
          let(:shopping_hbx_enrollment_member1){ FactoryGirl.build(:hbx_enrollment_member, applicant_id: family.family_members.second.id) }
          let(:shopping_hbx_enrollment_member2){ FactoryGirl.build(:hbx_enrollment_member, applicant_id: family.family_members.last.id) }
          let(:shopping_hbx_enrollment){FactoryGirl.build(:hbx_enrollment, aasm_state: 'shopping',hbx_enrollment_members: [shopping_hbx_enrollment_member, shopping_hbx_enrollment_member1, shopping_hbx_enrollment_member2], household: family.active_household)}

          it 'should return available APTC amount' do
            result = tax_household.total_aptc_available_amount_for_enrollment(shopping_hbx_enrollment)
            expect(result.round(2)).to eq(500.00)
          end
        end


        context 'having only one previous aptc enrollment & one non aptc enrollment' do

          let!(:hbx_enrollment_member1) { FactoryGirl.create(:hbx_enrollment_member, applicant_id: family.family_members.first.id, eligibility_date: current_date, coverage_start_on: current_date, hbx_enrollment: aptc_enrollment1, applied_aptc_amount: 278.68)}
          let!(:hbx_enrollment_member2) { FactoryGirl.create(:hbx_enrollment_member, applicant_id: family.family_members.second.id, eligibility_date: current_date, coverage_start_on: current_date, hbx_enrollment: aptc_enrollment1, applied_aptc_amount: 221.32)}
          let!(:hbx_enrollment_member3) { FactoryGirl.create(:hbx_enrollment_member, applicant_id: family.family_members.last.id, eligibility_date: current_date, coverage_start_on: current_date, hbx_enrollment: aptc_enrollment1)}
          let!(:aptc_enrollment1) {FactoryGirl.create(:hbx_enrollment, submitted_at: current_date + 1.months, household: family.active_household, is_active: true, aasm_state: 'coverage_selected', changing: false, effective_on: (current_date.beginning_of_month + 10.days), kind: 'individual', applied_aptc_amount: 500.00)}
          let(:shopping_hbx_enrollment_member1) { FactoryGirl.build(:hbx_enrollment_member, applicant_id: family.family_members.first.id, eligibility_date: current_date + 1.month) }
          let(:shopping_hbx_enrollment_member2) { FactoryGirl.build(:hbx_enrollment_member, applicant_id: family.family_members.second.id,eligibility_date: current_date + 1.month) }
          let(:shopping_hbx_enrollment_member3) { FactoryGirl.build(:hbx_enrollment_member, applicant_id: family.family_members.last.id,eligibility_date: current_date + 1.month) }
          let(:shopping_hbx_enrollment1) {FactoryGirl.build(:hbx_enrollment, coverage_kind: 'health', aasm_state: 'shopping', household: family.active_household, hbx_enrollment_members: [shopping_hbx_enrollment_member1, shopping_hbx_enrollment_member2,shopping_hbx_enrollment_member3])}

          before do
            eligibility_determination.update_attributes(max_aptc: 1000.00)
            aptc_enrollment1.household.reload
            hbx_enrollment.household.reload
            family.reload
          end

          it 'should have two enrollments in enrolled state for a family' do
            expect(family.active_household.hbx_enrollments.count).to eq(2)
          end
          it 'should return available APTC amount' do
            result = tax_household.total_aptc_available_amount_for_enrollment(shopping_hbx_enrollment1)
            expect(result.round(2)).to eq(500.00)
          end
        end

        context 'having two previous aptc enrollment with one enrolled member each and third member in shopping' do
          let!(:hbx_enrollment_member1) { FactoryGirl.create(:hbx_enrollment_member, applicant_id: family.family_members.first.id, eligibility_date: current_date, coverage_start_on: current_date, hbx_enrollment: aptc_enrollment1, applied_aptc_amount: 32.21)}
          let!(:aptc_enrollment1) {FactoryGirl.create(:hbx_enrollment,waiver_reason: nil, kind: 'individual', enrollment_kind: 'special_enrollment', coverage_kind: 'health', submitted_at: current_date - 2.months, aasm_state: 'coverage_selected', household: family.active_household, applied_aptc_amount: 32.21, effective_on: current_date)}
          let!(:hbx_enrollment_member2) { FactoryGirl.create(:hbx_enrollment_member, applicant_id: family.family_members.second.id, eligibility_date: current_date, coverage_start_on: current_date, hbx_enrollment: aptc_enrollment2, applied_aptc_amount: 278.68)}
          let!(:aptc_enrollment2) {FactoryGirl.create(:hbx_enrollment,waiver_reason: nil, submitted_at: current_date - 1.months, household: family.active_household,enrollment_kind: 'special_enrollment', is_active: true, aasm_state: 'coverage_selected', changing: false, kind: 'individual', applied_aptc_amount: 278.68, effective_on: current_date)}
          let(:shopping_hbx_enrollment_member1) { FactoryGirl.build(:hbx_enrollment_member, applicant_id: family.family_members.last.id,eligibility_date: current_date + 1.month) }
          let(:shopping_hbx_enrollment1) {FactoryGirl.build(:hbx_enrollment, coverage_kind: 'health', aasm_state: 'shopping', household: family.active_household, hbx_enrollment_members: [shopping_hbx_enrollment_member1], effective_on: current_date)}

          before do
            tax_household_member3.update_attributes(is_ia_eligible: true)
            eligibility_determination.update_attributes(max_aptc: 500.00)
            aptc_enrollment2.household.reload
            aptc_enrollment1.household.reload
            hbx_enrollment.household.reload
            family.reload
          end

          it 'should have two enrollments in enrolled state for a family' do
            expect(family.active_household.hbx_enrollments.count).to eq(3)
          end
          it 'should return available APTC amount' do
            result = tax_household.total_aptc_available_amount_for_enrollment(shopping_hbx_enrollment1)
            expect(result.round(2)).to eq(189.11)
          end
        end

        context 'when all checked family_members in plan shopping ' do
          let(:shopping_hbx_enrollment_member) { FactoryGirl.build(:hbx_enrollment_member, applicant_id: family.family_members.first.id) }
          let(:shopping_hbx_enrollment_member1) { FactoryGirl.build(:hbx_enrollment_member, applicant_id: family.family_members.second.id) }
          let(:shopping_hbx_enrollment_member2) { FactoryGirl.build(:hbx_enrollment_member, applicant_id: family.family_members.last.id) }
          let(:shopping_hbx_enrollment) { FactoryGirl.build(:hbx_enrollment, aasm_state: 'shopping',hbx_enrollment_members: [shopping_hbx_enrollment_member, shopping_hbx_enrollment_member1, shopping_hbx_enrollment_member2], household: family.active_household) }

          it 'should return all checked members' do
            expect(tax_household.find_enrolling_fms(shopping_hbx_enrollment).count).to eq(3)
          end
        end

        context 'having one member is enrolled and one member is unchecked and third member in shopping' do
          let!(:hbx_enrollment_member1) { FactoryGirl.create(:hbx_enrollment_member, applicant_id: family.family_members.first.id, eligibility_date: current_date, coverage_start_on: current_date, hbx_enrollment: aptc_enrollment1, applied_aptc_amount: 32.21) }
          let!(:aptc_enrollment1) {FactoryGirl.create(:hbx_enrollment,waiver_reason: nil, kind: 'individual', enrollment_kind: 'special_enrollment', coverage_kind: 'health', submitted_at: current_date - 2.months, aasm_state: 'coverage_selected', household: family.active_household, applied_aptc_amount: 32.21) }
          let!(:hbx_enrollment_member2) { FactoryGirl.create(:hbx_enrollment_member, applicant_id: family.family_members.first.id, eligibility_date: current_date, coverage_start_on: current_date, hbx_enrollment: hbx_enrollment) }
          let(:shopping_hbx_enrollment_member3) { FactoryGirl.build(:hbx_enrollment_member, applicant_id: family.family_members.last.id) }
          let(:shopping_hbx_enrollment) { FactoryGirl.build(:hbx_enrollment, aasm_state: 'shopping',hbx_enrollment_members: [shopping_hbx_enrollment_member3], household: family.active_household) }

          it 'should return only unwanted_family_members' do
            expect(tax_household.unwanted_family_members(shopping_hbx_enrollment).count).to eq(1)
          end
        end

        context 'having two previous aptc enrollment and third member in shopping' do
          let!(:hbx_enrollment_member1) { FactoryGirl.create(:hbx_enrollment_member, applicant_id: family.family_members.first.id, eligibility_date: current_date, coverage_start_on: current_date, hbx_enrollment: aptc_enrollment1, applied_aptc_amount: 32.21) }
          let!(:aptc_enrollment1) { FactoryGirl.create(:hbx_enrollment, waiver_reason: nil, kind: 'individual', enrollment_kind: 'special_enrollment', coverage_kind: 'health', submitted_at: current_date - 2.months, aasm_state: 'coverage_selected', household: family.active_household, applied_aptc_amount: 32.21) }
          let!(:hbx_enrollment_member2) { FactoryGirl.create(:hbx_enrollment_member, applicant_id: family.family_members.second.id, eligibility_date: current_date, coverage_start_on: current_date, hbx_enrollment: aptc_enrollment2, applied_aptc_amount: 278.68) }
          let!(:aptc_enrollment2) { FactoryGirl.create(:hbx_enrollment, waiver_reason: nil, submitted_at: current_date - 1.months, household: family.active_household, enrollment_kind: 'special_enrollment', is_active: true, aasm_state: 'coverage_selected', changing: false, kind: 'individual', applied_aptc_amount: 278.68)}
          let(:shopping_hbx_enrollment_member1) { FactoryGirl.build(:hbx_enrollment_member, applicant_id: family.family_members.last.id, eligibility_date: current_date + 1.month) }
          let(:shopping_hbx_enrollment1) { FactoryGirl.build(:hbx_enrollment, coverage_kind: 'health', aasm_state: 'shopping', household: family.active_household, hbx_enrollment_members: [shopping_hbx_enrollment_member1]) }

          it 'should return enrolled family_members' do
            expect(tax_household.aptc_family_members_by_tax_household.count).to eq(2)
          end
        end
        context 'first two family_members are in is_ia_eligible and third is medicaid ' do
          let(:shopping_hbx_enrollment_member2) { FactoryGirl.build(:hbx_enrollment_member, applicant_id: family.family_members.last.id) }
          let(:shopping_hbx_enrollment) { FactoryGirl.build(:hbx_enrollment, aasm_state: 'shopping', hbx_enrollment_members: [shopping_hbx_enrollment_member2], household: family.active_household) }

          it 'should return medicaid family_members only' do
            expect(tax_household.find_non_aptc_fms(shopping_hbx_enrollment.hbx_enrollment_members.map(&:family_member)).count).to eq(1)
          end
        end
      end
    end
  end
end
