require 'rails_helper'

RSpec.describe TaxHousehold, type: :model do
  let(:family)  { FactoryGirl.create(:family) }



# describe TaxHousehold do
=begin
  describe "validate associations" do
#	  it { should have_and_belong_to_many  :people }
#	  it { should embed_many :special_enrollment_periods }
	  it { should embed_many :eligibilities }
=end

  it "should have no people" do
    expect(subject.people).to be_empty
  end
=begin

  it "max_aptc and csr values returned are from the most recent eligibility record" do
  	hh = Household.new(
  			eligibilities: [
  				Eligibility.new({date_determined: Date.today - 100, max_aptc: 101.05, csr_percent: 1.0}),
  				Eligibility.new({date_determined: Date.today - 80, max_aptc: 181.05, csr_percent: 0.80}),
  				Eligibility.new({date_determined: Date.today, max_aptc: 287.95, csr_percent: 0.73}),
  				Eligibility.new({date_determined: Date.today - 50, max_aptc: 101.05, csr_percent: 0.50})
  			]
  		)

  	expect(hh.max_aptc).to eq(287.95)
  	expect(hh.csr_percent).to eq(0.73)
  end
  it "returns list of SEPs for specified day and single 'current_sep'" do
  	hh = Household.new(
  			special_enrollment_periods: [
  				SpecialEnrollmentPeriod.new({reason: "marriage", start_date: Date.today - 120, end_date: Date.today - 90}),
  				SpecialEnrollmentPeriod.new({reason: "retirement", start_date: Date.today - 10, end_date: Date.today + 20}),
  				SpecialEnrollmentPeriod.new({reason: "birth", start_date: Date.today - 90, end_date: Date.today - 60}),
  				SpecialEnrollmentPeriod.new({reason: "location_change", start_date: Date.today - 260, end_date: Date.today - 230}),
  				SpecialEnrollmentPeriod.new({reason: "employment_termination", start_date: Date.today - 180, end_date: Date.today - 150})
  			]
  		)

		past_day = hh.active_seps(Date.today - 500)
  	expect(past_day.count).to eq(0)

		wedding_day = hh.active_seps(Date.today - 120)
  	expect(wedding_day.count).to eq(1)
  	expect(wedding_day.first.reason).to eq("marriage")
  	expect(wedding_day.first.start_date).to eq(Date.today - 120)

  	expect(hh.current_sep.reason).to eq("retirement")
  	expect(hh.current_sep.start_date).to eq(Date.today - 10)
  end

  describe "new SEP effects on enrollment state:" do

		it "should initialize to closed_enrollment state" do
			hh = Household.new
			expect(hh.closed_enrollment?).to eq(true)
		end

		it "should transition to open_enrollment_period from any other enrollment state (including open_enrollment_period)" do
			hh = Household.new
			expect(hh.closed_enrollment?).to eq(true)
			hh.open_enrollment
			expect(hh.open_enrollment_period?).to eq(true)
			hh.open_enrollment
			expect(hh.open_enrollment_period?).to eq(true)
			hh.special_enrollment
			expect(hh.special_enrollment_period?).to eq(true)
			hh.open_enrollment
			expect(hh.open_enrollment_period?).to eq(true)
		end

		it "not affect state when system date is outside new SEP date range" do
			hh = Household.new
			hh.special_enrollment_periods << SpecialEnrollmentPeriod.new({reason: "marriage", start_date: Date.today - 120, end_date: Date.today - 90})
			expect(hh.closed_enrollment?).to eq(true)

			hh.special_enrollment
			hh.special_enrollment_periods << SpecialEnrollmentPeriod.new({reason: "location_change", start_date: Date.today - 90, end_date: Date.today - 60})
			expect(hh.special_enrollment_period?).to eq(true)
  	end

  	it "set state to special_enrollment_period when system date is within SEP date range" do
			hh = Household.new(rel: "subscriber")
			hh.special_enrollment_periods << SpecialEnrollmentPeriod.new({reason: "birth", start_date: Date.today - 5, end_date: Date.today + 25})
			hh.save!

			expect(hh.special_enrollment_period?).to eq(true)
			expect(hh.current_sep.reason).to eq("birth")
  	end

  	it "change state from open_enrollment_period to special_enrollment_period when end_date is later" do
			hh = Household.new(rel: "spouse")
			hh.special_enrollment_periods << SpecialEnrollmentPeriod.new({reason: "open_enrollment_start", start_date: Date.today - 30, end_date: Date.today + 5})
			hh.save!
			expect(hh.open_enrollment_period?).to eq(true)

			hh.special_enrollment_periods << SpecialEnrollmentPeriod.new({reason: "adoption", start_date: Date.today - 15, end_date: Date.today + 15})
			expect(hh.special_enrollment_period?).to eq(true)
  	end

  	it "do not change state from open_enrollment_period to special_enrollment_period when end_date is prior" do
			hh = Household.new(rel: "spouse")
			hh.special_enrollment_periods << SpecialEnrollmentPeriod.new({reason: "open_enrollment_start", start_date: Date.today - 30, end_date: Date.today + 5})
			hh.save!
			expect(hh.open_enrollment_period?).to eq(true)

			hh.special_enrollment_periods << SpecialEnrollmentPeriod.new({reason: "adoption", start_date: Date.today - 29, end_date: Date.today + 1})
			expect(hh.open_enrollment_period?).to eq(true)
  	end

		it "manually force active enrollment periods to close" do
		end

		it "change Household state when System date enters or exits current_sep range" do
		end
  end
=end

  context "aptc_ratio_by_member" do
    let!(:plan) {FactoryGirl.build(:plan, :with_premium_tables)}
    #let(:current_hbx) {double(benefit_sponsorship: double(current_benefit_period: double(second_lowest_cost_silver_plan: plan)))}
    let(:current_hbx) {double(benefit_sponsorship: double(benefit_coverage_periods: [benefit_coverage_period]))}
    let(:benefit_coverage_period) {double(contains?:true, second_lowest_cost_silver_plan: plan)}
    let(:tax_household_member1) {double(is_ia_eligible?: true, age_on_effective_date: 28, applicant_id: 'tax_member1')}
    let(:tax_household_member2) {double(is_ia_eligible?: true, age_on_effective_date: 26, applicant_id: 'tax_member2')}

    it "can return ratio hash" do
      allow(HbxProfile).to receive(:current_hbx).and_return(current_hbx)
      allow(plan).to receive(:premium_for).and_return(110)
      tax_household = TaxHousehold.new(effective_starting_on: TimeKeeper.date_of_record)
      allow(tax_household).to receive(:aptc_members).and_return([tax_household_member1, tax_household_member2])
      expect(tax_household.aptc_ratio_by_member.class).to eq Hash
      result = {"tax_member1"=>0.5, "tax_member2"=>0.5}
      expect(tax_household.aptc_ratio_by_member).to eq result
    end
  end

  context "aptc_available_amount_by_member" do
    let(:aptc_ratio_by_member) { {'member1'=>0.6, 'member2'=>0.4} }
    let(:hbx_member1) { double(applicant_id: 'member1', applied_aptc_amount: 20) }
    let(:hbx_member2) { double(applicant_id: 'member2', applied_aptc_amount: 10) }
    let(:hbx_enrollment) { double(applied_aptc_amount: 30, hbx_enrollment_members: [hbx_member1, hbx_member2]) }
    let(:household) { double }

    it "can return result" do
      tax_household = TaxHousehold.new()
      allow(tax_household).to receive(:household).and_return household
      allow(tax_household).to receive(:aptc_ratio_by_member).and_return aptc_ratio_by_member
      allow(tax_household).to receive(:current_max_aptc).and_return 100
      allow(tax_household).to receive(:effective_starting_on).and_return TimeKeeper.date_of_record
      allow(household).to receive(:hbx_enrollments_with_aptc_by_year).and_return([hbx_enrollment])
      expect(tax_household.aptc_available_amount_by_member.class).to eq Hash
      result = {'member1'=>40, 'member2'=>30}
      expect(tax_household.aptc_available_amount_by_member).to eq result
    end
  end

  context "aptc_available_amount_for_enrollment" do
    let(:aptc_available_amount_by_member) { {'member1'=>60, 'member2'=>40} }
    let(:hbx_member1) { double(applicant_id: 'member1') }
    let(:hbx_member2) { double(applicant_id: 'member2') }
    let(:hbx_enrollment) { double(applied_aptc_amount: 30, hbx_enrollment_members: [hbx_member1, hbx_member2]) }
    let(:household) { double }
    let!(:plan) {FactoryGirl.build(:plan, :with_premium_tables)}
    let(:decorated_plan) {double}

    before :each do
      @tax_household = TaxHousehold.new()
      allow(plan).to receive(:ehb).and_return 0.9
      allow(@tax_household).to receive(:aptc_available_amount_by_member).and_return aptc_available_amount_by_member
      allow(@tax_household).to receive(:total_aptc_available_amount_for_enrollment).and_return 100
      allow(UnassistedPlanCostDecorator).to receive(:new).and_return(decorated_plan)
      allow(decorated_plan).to receive(:premium_for).and_return(100)
      allow(household).to receive(:hbx_enrollments_with_aptc_by_date).and_return([hbx_enrollment])
    end

    it "can return result when plan is individual" do
      allow(plan).to receive(:coverage_kind).and_return 'individual'
      expect(@tax_household.aptc_available_amount_for_enrollment(hbx_enrollment, plan, 50).class).to eq Hash
      result = {'member1'=>30, 'member2'=>20}
      expect(@tax_household.aptc_available_amount_for_enrollment(hbx_enrollment, plan, 50)).to eq result
    end

    it "when ehb_premium > aptc_amount" do
      allow(decorated_plan).to receive(:premium_for).and_return(10)
      allow(plan).to receive(:coverage_kind).and_return 'individual'
      expect(@tax_household.aptc_available_amount_for_enrollment(hbx_enrollment, plan, 50).class).to eq Hash
      result = {'member1'=>9, 'member2'=>9}
      expect(@tax_household.aptc_available_amount_for_enrollment(hbx_enrollment, plan, 50)).to eq result
    end

    it "can return result when plan is dental" do
      allow(plan).to receive(:coverage_kind).and_return 'dental'
      expect(@tax_household.aptc_available_amount_for_enrollment(hbx_enrollment, plan, 50).class).to eq Hash
      result = {'member1'=>0, 'member2'=>0}
      expect(@tax_household.aptc_available_amount_for_enrollment(hbx_enrollment, plan, 50)).to eq result
    end

    it "can return result when total_aptc_available_amount is 0" do
      allow(@tax_household).to receive(:total_aptc_available_amount_for_enrollment).and_return 0
      allow(decorated_plan).to receive(:premium_for).and_return(10)
      allow(plan).to receive(:coverage_kind).and_return 'individual'
      expect(@tax_household.aptc_available_amount_for_enrollment(hbx_enrollment, plan, 50).class).to eq Hash
      result = {'member1'=>0, 'member2'=>0}
      expect(@tax_household.aptc_available_amount_for_enrollment(hbx_enrollment, plan, 50)).to eq result
    end
  end

  context "current_max_aptc" do
    before :each do
      @tax_household = TaxHousehold.new(effective_starting_on: TimeKeeper.date_of_record)
    end

    it "return max aptc when in the same year" do
      #allow(@tax_household).to receive(:latest_eligibility_determination).and_return(double(determined_on: TimeKeeper.date_of_record, max_aptc: 100))
      #expect(@tax_household.current_max_aptc).to eq 100
    end

    it "return 0 when not in the same year" do
      allow(@tax_household).to receive(:latest_eligibility_determination).and_return(double(determined_on: TimeKeeper.date_of_record + 1.year, max_aptc: 0))
      expect(@tax_household.current_max_aptc).to eq 0
    end
  end

  context "current_csr_eligibility_kind" do
    let(:eligibility_determination) {EligibilityDetermination.new(csr_eligibility_kind: 'csr_87', determined_on: TimeKeeper.date_of_record)}
    let(:tax_household) {TaxHousehold.new}

    it "should equal to the csr_eligibility_kind of latest_eligibility_determination" do
      tax_household.eligibility_determinations = [eligibility_determination]
      expect(tax_household.current_csr_eligibility_kind).to eq eligibility_determination.csr_eligibility_kind
    end
  end
end
