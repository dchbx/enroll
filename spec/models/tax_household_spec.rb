# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TaxHousehold, type: :model do
  let(:family)  { FactoryBot.create(:family) }



# describe TaxHousehold do
=begin
  describe "validate associations" do
#    it { should have_and_belong_to_many  :people }
#    it { should embed_many :special_enrollment_periods }
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
    let!(:plan) {FactoryBot.create(:benefit_markets_products_health_products_health_product, benefit_market_kind: :aca_individual, kind: :health, csr_variant_id: '01')}
    #let(:current_hbx) {double(benefit_sponsorship: double(current_benefit_period: double(second_lowest_cost_silver_plan: plan)))}
    let(:current_hbx) {double(benefit_sponsorship: double(benefit_coverage_periods: [benefit_coverage_period]))}
    let(:benefit_coverage_period) {double(contains?: true, second_lowest_cost_silver_plan: plan)}
    let(:tax_household_member1) {double(is_ia_eligible?: true, age_on_effective_date: 28, applicant_id: 'tax_member1')}
    let(:tax_household_member2) {double(is_ia_eligible?: true, age_on_effective_date: 26, applicant_id: 'tax_member2')}

    it "can return ratio hash" do
      allow(HbxProfile).to receive(:current_hbx).and_return(current_hbx)
      tax_household = TaxHousehold.new(effective_starting_on: TimeKeeper.date_of_record)
      allow(tax_household).to receive(:aptc_members).and_return([tax_household_member1, tax_household_member2])
      expect(tax_household.aptc_ratio_by_member.class).to eq Hash
      result = {"tax_member1" => 0.5, "tax_member2" => 0.5}
      expect(tax_household.aptc_ratio_by_member).to eq result
    end
  end

  context "aptc_available_amount_by_member" do
    let!(:family) {create(:family, :with_primary_family_member_and_dependent)}
    let(:household) {create(:household, family: family)}
    let(:aptc_ratio_by_member) { {'member1' => 0.6, 'member2' => 0.4} }
    let(:hbx_member1) { double(applicant_id: 'member1', applied_aptc_amount: 20) }
    let(:hbx_member2) { double(applicant_id: 'member2', applied_aptc_amount: 10) }
    let(:hbx_enrollment) { double(applied_aptc_amount: 30, family: family, hbx_enrollment_members: [hbx_member1, hbx_member2]) }
    # let(:household) { family.active_household }
    let(:monthly_available_aptc) { 100 }

    it "can return result" do
      tax_household = TaxHousehold.new
      allow(tax_household).to receive(:household).and_return household
      allow(tax_household).to receive(:aptc_ratio_by_member).and_return aptc_ratio_by_member
      allow(tax_household).to receive(:current_max_aptc).and_return 100
      allow(tax_household).to receive(:effective_starting_on).and_return TimeKeeper.date_of_record
      allow(household).to receive(:hbx_enrollments_with_aptc_by_year).and_return([hbx_enrollment])
      expect(tax_household.aptc_available_amount_by_member(monthly_available_aptc).class).to eq Hash
      result = {'member1' => 40, 'member2' => 30}
      expect(tax_household.aptc_available_amount_by_member(monthly_available_aptc)).to eq result
    end
  end

  context "aptc_available_amount_for_enrollment" do
    let!(:family) {create(:family, :with_primary_family_member_and_dependent)}
    let(:household) {create(:household, family: family)}
    let(:aptc_available_amount_by_member) { {'member1' => 60, 'member2' => 40} }
    let(:hbx_member1) { double(applicant_id: 'member1') }
    let(:hbx_member2) { double(applicant_id: 'member2') }
    let(:hbx_enrollment) { double(applied_aptc_amount: 30, family: family, hbx_enrollment_members: [hbx_member1, hbx_member2]) }
    # let(:household) { double }
    let!(:plan) {FactoryBot.create(:benefit_markets_products_health_products_health_product, benefit_market_kind: :aca_individual, kind: :health, csr_variant_id: '01')}
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

    it "can return result when plan is individual" do
      allow(plan).to receive(:kind).and_return 'individual'
      #allow(@tax_household).to receive(:deduct_aptc_available_amount_for_unenrolled).and_return 20
      expect(@tax_household.aptc_available_amount_for_enrollment(hbx_enrollment, plan, 50).class).to eq Hash
      result = {'member1' => 30, 'member2' => 20}
      expect(@tax_household.aptc_available_amount_for_enrollment(hbx_enrollment, plan, 50)).to eq result
    end

    it "when ehb_premium > aptc_amount" do
      allow(decorated_plan).to receive(:premium_for).and_return(10)
      allow(plan).to receive(:kind).and_return 'individual'
      #allow(@tax_household).to receive(:deduct_aptc_available_amount_for_unenrolled).and_return 20
      expect(@tax_household.aptc_available_amount_for_enrollment(hbx_enrollment, plan, 50).class).to eq Hash
      result = {'member1' => 9, 'member2' => 9}
      expect(@tax_household.aptc_available_amount_for_enrollment(hbx_enrollment, plan, 50)).to eq result
    end

    it "can return result when plan is dental" do
      allow(plan).to receive(:kind).and_return 'dental'
      #allow(@tax_household).to receive(:deduct_aptc_available_amount_for_unenrolled).and_return 20
      expect(@tax_household.aptc_available_amount_for_enrollment(hbx_enrollment, plan, 50).class).to eq Hash
      result = {'member1' => 0, 'member2' => 0}
      expect(@tax_household.aptc_available_amount_for_enrollment(hbx_enrollment, plan, 50)).to eq result
    end

    it "can return result when total_aptc_available_amount is 0" do
      allow(@tax_household).to receive(:total_aptc_available_amount_for_enrollment).and_return 0
      allow(decorated_plan).to receive(:premium_for).and_return(10)
      allow(plan).to receive(:kind).and_return 'individual'
      #allow(@tax_household).to receive(:deduct_aptc_available_amount_for_unenrolled).and_return 20
      expect(@tax_household.aptc_available_amount_for_enrollment(hbx_enrollment, plan, 50).class).to eq Hash
      result = {'member1' => 0, 'member2' => 0}
      expect(@tax_household.aptc_available_amount_for_enrollment(hbx_enrollment, plan, 50)).to eq result
    end
  end

  context "current_max_aptc" do
    before :each do
      @tax_household = TaxHousehold.new(effective_starting_on: TimeKeeper.date_of_record)
    end

    it "return max aptc when in the same year" do
      #allow(@tax_household).to receive(:latest_eligibility_determination).and_return(double(determined_at: TimeKeeper.date_of_record, max_aptc: 100))
      #expect(@tax_household.current_max_aptc).to eq 100
    end

    it "return 0 when not in the same year" do
      allow(@tax_household).to receive(:latest_eligibility_determination).and_return(double(determined_at: TimeKeeper.date_of_record + 1.year, max_aptc: 0))
      expect(@tax_household.current_max_aptc).to eq 0
    end
  end

  context "current_csr_eligibility_kind" do
    let(:eligibility_determination) {EligibilityDetermination.new(csr_eligibility_kind: 'csr_87', determined_at: TimeKeeper.date_of_record)}
    let(:tax_household) {TaxHousehold.new}

    it "should equal to the csr_eligibility_kind of latest_eligibility_determination" do
      tax_household.eligibility_determinations = [eligibility_determination]
      expect(tax_household.current_csr_eligibility_kind).to eq eligibility_determination.csr_eligibility_kind
    end
  end

  context "valid_csr_kind" do
    let!(:family) {create(:family, :with_primary_family_member_and_dependent)}
    let(:household) {create(:household, family: family)}
    let(:hbx_member1) { double(applicant_id: 'member1') }
    let(:hbx_member2) { double(applicant_id: 'member2') }
    let(:hbx_enrollment) { double(hbx_enrollment_members: [hbx_member1, hbx_member2], family: family) }
    let(:eligibility_determination) {EligibilityDetermination.new(csr_eligibility_kind: 'csr_87', determined_at: TimeKeeper.date_of_record)}
    let(:tax_household) do
      tax_household = TaxHousehold.new
      tax_household.tax_household_members.build(is_ia_eligible: true, applicant_id: 'member1')
      tax_household.tax_household_members.build(is_ia_eligible: true, applicant_id: 'member2')
      tax_household
    end

    before do
      allow(tax_household).to receive(:eligibility_determinations).and_return([eligibility_determination])
    end

    it "should equal to the csr_kind of latest_eligibility_determination" do
      tax_household.eligibility_determinations = [eligibility_determination]
      expect(tax_household.valid_csr_kind(hbx_enrollment)).to eq eligibility_determination.csr_eligibility_kind
    end
  end

  context 'for current_csr_percent_as_integer' do
    let(:ed) {EligibilityDetermination.new(csr_percent_as_integer: 73, determined_at: TimeKeeper.date_of_record)}
    let(:thh) {TaxHousehold.new}

    it 'should equal to the csr_eligibility_kind of latest_eligibility_determination' do
      thh.eligibility_determinations = [ed]
      expect(thh.current_csr_percent_as_integer).to eq ed.csr_percent_as_integer
    end
  end

  context 'is_all_non_aptc?' do
    let!(:family) {create(:family, :with_primary_family_member_and_dependent)}
    let(:household) {create(:household, family: family)}
    let!(:tax_household) {create(:tax_household, household: household)}
    let(:hbx_enrollment) {create(:hbx_enrollment, :with_enrollment_members, family: family, household: household)}

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
    let!(:hbx_profile) {FactoryBot.create(:hbx_profile, :open_enrollment_coverage_period)}
    let!(:family) { create(:family, :with_primary_family_member_and_dependent) }
    let!(:person) { family.primary_person }
    let(:household) { family.active_household }
    let!(:tax_household) { create(:tax_household, household: household, effective_ending_on: nil) }
    let!(:tax_household_member1) {tax_household.tax_household_members.create!(is_ia_eligible: true, applicant_id: person.primary_family.family_members[0].id)}
    let!(:tax_household_member2) {tax_household.tax_household_members.create!(is_ia_eligible: true, applicant_id: person.primary_family.family_members[1].id)}
    let!(:tax_household_member3) {tax_household.tax_household_members.create!(is_ia_eligible: true, applicant_id: person.primary_family.family_members[2].id)}
    let!(:eligibility) { FactoryBot.create(:eligibility_determination, tax_household: tax_household, max_aptc: 210) }
    let(:hbx_enrollment) { create(:hbx_enrollment, :with_enrollment_members, family: family, household: household) }
    let(:member_ids) { family.active_family_members.collect(&:id) }
    let(:benefit_sponsorship) {double("benefit sponsorship", earliest_effective_date: TimeKeeper.date_of_record.beginning_of_year)}
    let(:current_hbx) {double("current hbx", benefit_sponsorship: benefit_sponsorship, under_open_enrollment?: true)}
    let(:product) { FactoryBot.create(:benefit_markets_products_health_products_health_product) }
    let(:total_aptc_available_amount) { 210 }
    let(:monthly_available_aptc) { 1260.0 }
    let!(:hbx_enrollment_aptc) do
      FactoryBot.create(:hbx_enrollment,  :with_health_product,
                        waiver_reason: nil, kind: 'individual', enrollment_kind: 'special_enrollment',
                        coverage_kind: 'health', effective_on: Date.new(TimeKeeper.date_of_record.year, 11, 1),submitted_at: TimeKeeper.date_of_record - 6.months,
                        household: family.active_household, family: family, product: product)
    end

    before :each do
      hbx_profile.benefit_sponsorship.benefit_coverage_periods.detect {|bcp| bcp.contains?(TimeKeeper.datetime_of_record)}.update_attributes!(slcsp_id: product.id)
    end

    context 'when all family members checked' do
      before do
        allow(tax_household).to receive(:unwanted_family_members).and_return []
      end

      context 'when all family_members are eligible and monthly aggregate feature is turned OFF' do
        before do
          allow(tax_household).to receive(:is_all_non_aptc?).and_return false
          EnrollRegistry[:calculate_monthly_aggregate].feature.stub(:is_enabled).and_return(false)
        end

        it 'should return all members amount' do
          result = tax_household.total_aptc_available_amount_for_enrollment(hbx_enrollment_aptc)
          expect(result).to eq(total_aptc_available_amount)
        end
      end

      context 'when all family_members eligible and monthly aggregate feature is turned ON' do
        before do
          allow(tax_household).to receive(:is_all_non_aptc?).and_return false
          EnrollRegistry[:calculate_monthly_aggregate].feature.stub(:is_enabled).and_return(true)
        end

        it 'should return all members amount' do
          result = tax_household.total_aptc_available_amount_for_enrollment(hbx_enrollment_aptc)
          expect(result).to eq(monthly_available_aptc)
        end
      end

      context 'when all family_members are non eligible members for aptc' do
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

      context 'When calculate_yearly_aggregate feature is turned OFF' do
        before do
          EnrollRegistry[:calculate_monthly_aggregate].feature.stub(:is_enabled).and_return(false)
        end

        it 'should deduct benchmark cost' do
          result = tax_household.total_aptc_available_amount_for_enrollment(hbx_enrollment)
          expect(result).not_to eq(total_aptc_available_amount)
          expect(result).to eq(total_aptc_available_amount - total_benchmark_amount)
        end
      end

      context 'When calculate_yearly_aggregate feature is turned ON' do
        before do
          EnrollRegistry[:calculate_monthly_aggregate].feature.stub(:is_enabled).and_return(true)
        end

        it 'should deduct benchmark cost' do
          result = tax_household.total_aptc_available_amount_for_enrollment(hbx_enrollment_aptc)
          expect(result).not_to eq(total_aptc_available_amount)
          expect(result).to eq(monthly_available_aptc - total_benchmark_amount)
        end
      end
    end
  end

  describe "total_aptc_available_amount_for_enrollment", dbclean: :after_each do

    context 'for family_members with two aptc eligible and one medicaid' do

      let!(:hbx_profile) {FactoryBot.create(:hbx_profile, :open_enrollment_coverage_period)}
      let(:plan) {FactoryBot.create(:plan, :with_premium_tables, market: 'individual', metal_level: 'silver', csr_variant_id: '01', active_year: TimeKeeper.date_of_record.year, hios_id: '94506DC0390014-01')}

      let!(:person) {FactoryBot.create(:person, :with_family)}
      let!(:family) {person.primary_family}
      let!(:family_member1) {FactoryBot.create(:family_member, family: person.primary_family)}
      let!(:family_member2) {FactoryBot.create(:family_member, family: person.primary_family)}
      let(:member_ids) {family.active_family_members.collect(&:id)}
      let!(:hbx_enrollment_member1) {FactoryBot.create(:hbx_enrollment_member, applicant_id: family.family_members.first.id, eligibility_date: TimeKeeper.date_of_record, coverage_start_on: TimeKeeper.date_of_record, hbx_enrollment: hbx_enrollment)}
      let!(:hbx_enrollment_member2) {FactoryBot.create(:hbx_enrollment_member, applicant_id: family.family_members.second.id, eligibility_date: TimeKeeper.date_of_record, coverage_start_on: TimeKeeper.date_of_record, hbx_enrollment: hbx_enrollment)}
      let!(:hbx_enrollment_member3) {FactoryBot.create(:hbx_enrollment_member, applicant_id: family.family_members.last.id, eligibility_date: TimeKeeper.date_of_record, coverage_start_on: TimeKeeper.date_of_record, hbx_enrollment: hbx_enrollment)}
      let(:product) { FactoryBot.create(:benefit_markets_products_health_products_health_product) }
      let!(:hbx_enrollment) do
        FactoryBot.create(:hbx_enrollment,  :with_health_product,
                          waiver_reason: nil, kind: 'individual', enrollment_kind: 'special_enrollment',
                          coverage_kind: 'health', submitted_at: TimeKeeper.date_of_record - 6.months,
                          household: family.active_household, family: family, product: product)
      end
      let!(:tax_household) {FactoryBot.create(:tax_household, household: family.active_household, created_at: TimeKeeper.date_of_record - 5.months, effective_ending_on: nil)}
      let!(:tax_household_member1) {tax_household.tax_household_members.create!(is_ia_eligible: true, applicant_id: person.primary_family.family_members[0].id)}
      let!(:tax_household_member2) {tax_household.tax_household_members.create!(is_ia_eligible: true, applicant_id: person.primary_family.family_members[1].id)}
      let!(:tax_household_member3) {tax_household.tax_household_members.create!(is_ia_eligible: false, is_medicaid_chip_eligible: true, applicant_id: person.primary_family.family_members[2].id)}
      let!(:eligibility_determination) {FactoryBot.create(:eligibility_determination, max_aptc: 500, tax_household: tax_household)}

      before do
        hbx_profile.benefit_sponsorship.benefit_coverage_periods.detect {|bcp| bcp.contains?(TimeKeeper.datetime_of_record)}.update_attributes!(slcsp_id: product.id)
        person.update_attributes!(dob: TimeKeeper.date_of_record - 38.years)
        person.primary_family.family_members[1].person.update_attributes!(dob: TimeKeeper.date_of_record - 28.years)
        person.primary_family.family_members[2].person.update_attributes!(dob: TimeKeeper.date_of_record - 18.years)
      end

      context 'having only one previous non aptc enrollment' do
        context 'when one family_member in plan shopping' do

          let(:shopping_hbx_enrollment_member) {FactoryBot.build(:hbx_enrollment_member, applicant_id: family.family_members.first.id)}
          let(:product) { FactoryBot.create(:benefit_markets_products_health_products_health_product) }

          let(:shopping_hbx_enrollment) do
            FactoryBot.build(:hbx_enrollment,
                             family: family, aasm_state: 'shopping',
                             effective_on: TimeKeeper.date_of_record.beginning_of_month,
                             hbx_enrollment_members: [shopping_hbx_enrollment_member],
                             household: family.active_household, product: product)
          end

          context "When yearly aggregate feature is turned OFF" do
            before do
              EnrollRegistry[:calculate_monthly_aggregate].feature.stub(:is_enabled).and_return(false)
            end

            it 'should return available APTC amount' do
              result = tax_household.total_aptc_available_amount_for_enrollment(shopping_hbx_enrollment)
              expect(result).to eq(301.14)
            end
          end

          context "When yearly aggregate feature is turned ON" do
            before do
              shopping_hbx_enrollment.update_attributes(effective_on: Date.new(TimeKeeper.date_of_record.year, 11, 1))
              EnrollRegistry[:calculate_monthly_aggregate].feature.stub(:is_enabled).and_return(true)
            end

            it 'should return available APTC amount' do
              result = tax_household.total_aptc_available_amount_for_enrollment(shopping_hbx_enrollment)
              expect(result).to eq(2801.14)
            end
          end
        end

        context 'when two family_members in plan shopping' do

          let(:shopping_hbx_enrollment_member) {FactoryBot.build(:hbx_enrollment_member, eligibility_date: TimeKeeper.date_of_record + 1.month, applicant_id: family.family_members.first.id)}
          let(:shopping_hbx_enrollment_member1) {FactoryBot.build(:hbx_enrollment_member, eligibility_date: TimeKeeper.date_of_record + 1.month, applicant_id: family.family_members.second.id)}
          let(:product) { FactoryBot.create(:benefit_markets_products_health_products_health_product) }
          let(:shopping_hbx_enrollment) {FactoryBot.build(:hbx_enrollment, family: family, aasm_state: 'shopping', hbx_enrollment_members: [shopping_hbx_enrollment_member, shopping_hbx_enrollment_member1], household: family.active_household, product: product)}

          context "When yearly aggregate feature is turned OFF" do
            before do
              EnrollRegistry[:calculate_monthly_aggregate].feature.stub(:is_enabled).and_return(false)
            end

            it 'should return available APTC amount' do
              result = tax_household.total_aptc_available_amount_for_enrollment(shopping_hbx_enrollment)
              expect(result).to eq(500.00)
            end
          end

          context "When yearly aggregate feature is turned ON" do
            before do
              shopping_hbx_enrollment.update_attributes(effective_on: Date.new(TimeKeeper.date_of_record.year, 11, 1))
              EnrollRegistry[:calculate_monthly_aggregate].feature.stub(:is_enabled).and_return(true)
            end

            it 'should return available APTC amount' do
              result = tax_household.total_aptc_available_amount_for_enrollment(shopping_hbx_enrollment)
              expect(result).to eq(3000.0)
            end
          end
        end

        context 'when all family_members in plan shopping' do

          let(:shopping_hbx_enrollment_member) {FactoryBot.build(:hbx_enrollment_member, applicant_id: family.family_members.first.id)}
          let(:shopping_hbx_enrollment_member1) {FactoryBot.build(:hbx_enrollment_member, applicant_id: family.family_members.second.id)}
          let(:shopping_hbx_enrollment_member2) {FactoryBot.build(:hbx_enrollment_member, applicant_id: family.family_members.last.id)}
          let(:product) { FactoryBot.create(:benefit_markets_products_health_products_health_product) }
          let(:shopping_hbx_enrollment) do
            FactoryBot.build(:hbx_enrollment, aasm_state: 'shopping',family: family, hbx_enrollment_members: [shopping_hbx_enrollment_member, shopping_hbx_enrollment_member1, shopping_hbx_enrollment_member2], household: family.active_household, product: product)
          end

          context "When yearly aggregate feature is turned OFF" do
            before do
              EnrollRegistry[:calculate_monthly_aggregate].feature.stub(:is_enabled).and_return(false)
            end

            it 'should return available APTC amount' do
              result = tax_household.total_aptc_available_amount_for_enrollment(shopping_hbx_enrollment)
              expect(result).to eq(500.00)
            end
          end

          context "When yearly aggregate feature is turned ON" do
            before do
              shopping_hbx_enrollment.update_attributes(effective_on: Date.new(TimeKeeper.date_of_record.year, 11, 1))
              EnrollRegistry[:calculate_monthly_aggregate].feature.stub(:is_enabled).and_return(true)
            end

            it 'should return available APTC amount' do
              result = tax_household.total_aptc_available_amount_for_enrollment(shopping_hbx_enrollment)
              expect(result).to eq(3000.0)
            end
          end
        end

        context 'having only one previous aptc enrollment & one non aptc enrollment' do

          let!(:hbx_enrollment_member1) do
            FactoryBot.create(:hbx_enrollment_member,
                              applicant_id: family.family_members.first.id,
                              eligibility_date: TimeKeeper.date_of_record,
                              coverage_start_on: TimeKeeper.date_of_record,
                              hbx_enrollment: aptc_enrollment1,
                              applied_aptc_amount: 278.68)
          end

          let!(:hbx_enrollment_member2) do
            FactoryBot.create(:hbx_enrollment_member,
                              applicant_id: family.family_members.second.id,
                              eligibility_date: TimeKeeper.date_of_record,
                              coverage_start_on: TimeKeeper.date_of_record,
                              hbx_enrollment: aptc_enrollment1,
                              applied_aptc_amount: 221.32)
          end
          let!(:hbx_enrollment_member3) do
            FactoryBot.create(:hbx_enrollment_member, applicant_id: family.family_members.last.id, eligibility_date: TimeKeeper.date_of_record, coverage_start_on: TimeKeeper.date_of_record, hbx_enrollment: aptc_enrollment1)
          end
          let!(:aptc_enrollment1) do
            FactoryBot.create(:hbx_enrollment,
                              family: family,
                              submitted_at: TimeKeeper.date_of_record + 1.month,
                              household: family.active_household,
                              is_active: true,
                              aasm_state: 'coverage_selected',
                              changing: false,
                              effective_on: (TimeKeeper.date_of_record.beginning_of_month + 10.days),
                              kind: 'individual',
                              applied_aptc_amount: 500.00)
          end
          let(:shopping_hbx_enrollment_member1) {FactoryBot.build(:hbx_enrollment_member, applicant_id: family.family_members.first.id, eligibility_date: TimeKeeper.date_of_record + 1.month)}
          let(:shopping_hbx_enrollment_member2) {FactoryBot.build(:hbx_enrollment_member, applicant_id: family.family_members.second.id, eligibility_date: TimeKeeper.date_of_record + 1.month)}
          let(:shopping_hbx_enrollment_member3) do
            FactoryBot.build(:hbx_enrollment_member,
                             applicant_id: family.family_members.last.id,
                             eligibility_date: TimeKeeper.date_of_record + 1.month)
          end

          let(:shopping_hbx_enrollment1) do
            FactoryBot.build(:hbx_enrollment,
                             family: family,
                             coverage_kind: 'health',
                             aasm_state: 'shopping',
                             household: family.active_household,
                             hbx_enrollment_members: [shopping_hbx_enrollment_member1,
                                                      shopping_hbx_enrollment_member2,
                                                      shopping_hbx_enrollment_member3])
          end

          before do
            eligibility_determination.update_attributes(max_aptc: 1000.00)
            aptc_enrollment1.household.reload
            hbx_enrollment.household.reload
            family.reload
          end

          it 'should have two enrollments in enrolled state for a family' do
            expect(family.active_household.hbx_enrollments.count).to eq(2)
          end

          context "When yearly aggregate feature is turned OFF" do
            before do
              EnrollRegistry[:calculate_monthly_aggregate].feature.stub(:is_enabled).and_return(false)
            end

            it 'should return available APTC amount' do
              result = tax_household.total_aptc_available_amount_for_enrollment(shopping_hbx_enrollment1)
              expect(result.round(2)).to eq(500.00)
            end
          end

          context "When yearly aggregate feature is turned ON" do
            before do
              shopping_hbx_enrollment1.update_attributes(effective_on: Date.new(TimeKeeper.date_of_record.year, 11, 1))
              EnrollRegistry[:calculate_monthly_aggregate].feature.stub(:is_enabled).and_return(true)
            end

            it 'should return available APTC amount' do
              result = tax_household.total_aptc_available_amount_for_enrollment(shopping_hbx_enrollment1)
              expect(result.round(2)).to eq(5080.0)
            end
          end
        end

        context 'having two previous aptc enrollment with one enrolled member each and third member in shopping' do
          let!(:hbx_enrollment_member1) do
            FactoryBot.create(:hbx_enrollment_member,
                              applicant_id: family.family_members.first.id,
                              eligibility_date: TimeKeeper.date_of_record,
                              coverage_start_on: TimeKeeper.date_of_record,
                              hbx_enrollment: aptc_enrollment1,
                              applied_aptc_amount: 32.21)
          end

          let!(:aptc_enrollment1) do
            FactoryBot.create(:hbx_enrollment,
                              family: family,
                              waiver_reason: nil,
                              kind: 'individual',
                              enrollment_kind: 'special_enrollment',
                              coverage_kind: 'health',
                              submitted_at: TimeKeeper.date_of_record - 2.months,
                              effective_on: TimeKeeper.date_of_record.beginning_of_month,
                              aasm_state: 'coverage_selected',
                              household: family.active_household,
                              applied_aptc_amount: 32.21)
          end

          let!(:hbx_enrollment_member2) do
            FactoryBot.create(:hbx_enrollment_member,
                              applicant_id: family.family_members.second.id,
                              eligibility_date: TimeKeeper.date_of_record,
                              coverage_start_on: TimeKeeper.date_of_record,
                              hbx_enrollment: aptc_enrollment2,
                              applied_aptc_amount: 278.68)
          end

          let!(:aptc_enrollment2) do
            FactoryBot.create(:hbx_enrollment,
                              family: family,
                              waiver_reason: nil,
                              submitted_at: TimeKeeper.date_of_record - 1.month,
                              effective_on: TimeKeeper.date_of_record.beginning_of_month,
                              household: family.active_household,
                              enrollment_kind: 'special_enrollment',
                              is_active: true,
                              aasm_state: 'coverage_selected',
                              changing: false,
                              kind: 'individual',
                              applied_aptc_amount: 278.68)
          end

          let(:shopping_hbx_enrollment_member1) do
            FactoryBot.build(:hbx_enrollment_member,
                             applicant_id: family.family_members.last.id,
                             eligibility_date: TimeKeeper.date_of_record + 1.month)
          end
          let(:shopping_hbx_enrollment1) do
            FactoryBot.build(:hbx_enrollment,
                             family: family, coverage_kind: 'health',
                             effective_on: TimeKeeper.date_of_record.beginning_of_month,
                             household: family.active_household, aasm_state: 'shopping',
                             hbx_enrollment_members: [shopping_hbx_enrollment_member1])
          end

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

          context "When yearly aggregate feature is turned OFF" do
            before do
              EnrollRegistry[:calculate_monthly_aggregate].feature.stub(:is_enabled).and_return(false)
            end

            it 'should return available APTC amount' do
              result = tax_household.total_aptc_available_amount_for_enrollment(shopping_hbx_enrollment1)
              expect(result.round(2)).to eq(189.11)
            end
          end

          context "When yearly aggregate feature is turned ON" do
            before do
              shopping_hbx_enrollment1.update_attributes(effective_on: Date.new(TimeKeeper.date_of_record.year, 11, 1))
              aptc_enrollment1.update_attributes(effective_on: Date.new(TimeKeeper.date_of_record.year, 10, 1))
              aptc_enrollment2.update_attributes(effective_on: Date.new(TimeKeeper.date_of_record.year, 10, 1))
              EnrollRegistry[:calculate_monthly_aggregate].feature.stub(:is_enabled).and_return(true)
            end

            it 'should return available APTC amount' do
              result = tax_household.total_aptc_available_amount_for_enrollment(shopping_hbx_enrollment1)
              expect(result.round(2)).to eq(2533.67)
            end
          end
        end

        context 'when all checked family_members in plan shopping ' do
          let(:shopping_hbx_enrollment_member){ FactoryBot.build(:hbx_enrollment_member, applicant_id: family.family_members.first.id) }
          let(:shopping_hbx_enrollment_member1){ FactoryBot.build(:hbx_enrollment_member, applicant_id: family.family_members.second.id) }
          let(:shopping_hbx_enrollment_member2){ FactoryBot.build(:hbx_enrollment_member, applicant_id: family.family_members.last.id) }
          let(:shopping_hbx_enrollment) do
            FactoryBot.build(:hbx_enrollment,
                             family: family,
                             aasm_state: "shopping",
                             hbx_enrollment_members: [shopping_hbx_enrollment_member, shopping_hbx_enrollment_member1, shopping_hbx_enrollment_member2],
                             household: family.active_household)
          end

          it 'should return all checked members' do
            expect(tax_household.find_enrolling_fms(shopping_hbx_enrollment).count).to eq(3)
          end
        end

        context 'having one member is enrolled and one member is unchecked and third member in shopping' do
          let!(:hbx_enrollment_member1) do
            FactoryBot.create(:hbx_enrollment_member,
                              applicant_id: family.family_members.first.id,
                              eligibility_date: TimeKeeper.date_of_record,
                              coverage_start_on: TimeKeeper.date_of_record,
                              hbx_enrollment: aptc_enrollment1,
                              applied_aptc_amount: 32.21)
          end

          let!(:aptc_enrollment1) do
            FactoryBot.create(:hbx_enrollment,
                              family: family,
                              waiver_reason: nil,
                              kind: 'individual',
                              enrollment_kind: 'special_enrollment',
                              coverage_kind: 'health',
                              submitted_at: TimeKeeper.date_of_record - 2.months,
                              aasm_state: 'coverage_selected',
                              household: family.active_household,
                              applied_aptc_amount: 32.21)
          end

          let!(:hbx_enrollment_member2) do
            FactoryBot.create(:hbx_enrollment_member,
                              applicant_id: family.family_members.first.id,
                              eligibility_date: TimeKeeper.date_of_record,
                              coverage_start_on: TimeKeeper.date_of_record,
                              hbx_enrollment: hbx_enrollment)
          end
          let(:shopping_hbx_enrollment_member3) {FactoryBot.build(:hbx_enrollment_member, applicant_id: family.family_members.last.id)}
          let(:shopping_hbx_enrollment) {FactoryBot.build(:hbx_enrollment, family: family, aasm_state: 'shopping', hbx_enrollment_members: [shopping_hbx_enrollment_member3], household: family.active_household)}

          it 'should return only unwanted_family_members' do
            expect(tax_household.unwanted_family_members(shopping_hbx_enrollment).count).to eq(1)
          end
        end

        context 'having two previous aptc enrollment and third member in shopping' do
          let!(:hbx_enrollment_member1) do
            FactoryBot.create(:hbx_enrollment_member,
                              applicant_id: family.family_members.first.id,
                              eligibility_date: TimeKeeper.date_of_record,
                              coverage_start_on: TimeKeeper.date_of_record,
                              hbx_enrollment: aptc_enrollment1,
                              applied_aptc_amount: 32.21)
          end

          let!(:aptc_enrollment1) do
            FactoryBot.create(:hbx_enrollment,
                              family: family,
                              waiver_reason: nil,
                              kind: 'individual',
                              enrollment_kind: 'special_enrollment',
                              coverage_kind: 'health',
                              submitted_at: TimeKeeper.date_of_record - 2.months,
                              aasm_state: 'coverage_selected',
                              household: family.active_household,
                              applied_aptc_amount: 32.21)
          end

          let!(:hbx_enrollment_member2) do
            FactoryBot.create(:hbx_enrollment_member,
                              applicant_id: family.family_members.second.id,
                              eligibility_date: TimeKeeper.date_of_record,
                              coverage_start_on: TimeKeeper.date_of_record,
                              hbx_enrollment: aptc_enrollment2,
                              applied_aptc_amount: 278.68)
          end

          let!(:aptc_enrollment2) do
            FactoryBot.create(:hbx_enrollment,
                              family: family,
                              waiver_reason: nil,
                              submitted_at: TimeKeeper.date_of_record - 1.month,
                              household: family.active_household,
                              enrollment_kind: 'special_enrollment',
                              is_active: true,
                              aasm_state: 'coverage_selected',
                              changing: false,
                              kind: 'individual',
                              applied_aptc_amount: 278.68)
          end

          let(:shopping_hbx_enrollment_member1) {FactoryBot.build(:hbx_enrollment_member, applicant_id: family.family_members.last.id, eligibility_date: TimeKeeper.date_of_record + 1.month)}
          let(:shopping_hbx_enrollment1) {FactoryBot.build(:hbx_enrollment, family: family, coverage_kind: 'health', aasm_state: 'shopping', household: family.active_household, hbx_enrollment_members: [shopping_hbx_enrollment_member1])}

          it 'should return enrolled family_members' do
            expect(tax_household.aptc_family_members_by_tax_household.count).to eq(2)
          end
        end
        context 'first two family_members are in is_ia_eligible and third is medicaid ' do
          let(:shopping_hbx_enrollment_member2) {FactoryBot.build(:hbx_enrollment_member, applicant_id: family.family_members.last.id)}
          let(:shopping_hbx_enrollment) {FactoryBot.build(:hbx_enrollment, family: family, aasm_state: 'shopping', hbx_enrollment_members: [shopping_hbx_enrollment_member2], household: family.active_household)}

          it 'should return medicaid family_members only' do
            expect(tax_household.find_non_aptc_fms(shopping_hbx_enrollment.hbx_enrollment_members.map(&:family_member)).count).to eq(1)
          end
        end
      end
    end
  end
end
