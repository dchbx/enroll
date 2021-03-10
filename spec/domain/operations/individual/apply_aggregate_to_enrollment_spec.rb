# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Operations::Individual::ApplyAggregateToEnrollment do

  context 'for invalid params' do
    it 'should return a failure with a message' do
      expect(subject.call({eligibility_determination: 'eligibility_determination'}).failure).to eq('Given object is not a valid eligibility determination object')
    end
  end

  let!(:plan) {FactoryBot.create(:benefit_markets_products_health_products_health_product, benefit_market_kind: :aca_individual, kind: :health, csr_variant_id: '01')}
  # let(:benefit_coverage_period) {double(contains?: true, second_lowest_cost_silver_plan: plan)}
  let!(:hbx_profile) {FactoryBot.create(:hbx_profile, :open_enrollment_coverage_period)}
  let!(:person) {FactoryBot.create(:person, :with_consumer_role, :with_active_consumer_role)}
  let!(:family) {FactoryBot.create(:family, :with_primary_family_member, person: person)}
  let!(:primary_fm) {family.primary_applicant}
  let!(:household) {family.active_household}
  let!(:start_on) {TimeKeeper.date_of_record.beginning_of_year}
  let(:family_member1) {FactoryBot.create(:family_member, family: household.family)}
  let!(:tax_household) do
    tax_household = FactoryBot.create(:tax_household, effective_ending_on: nil, household: family.households.first)
    FactoryBot.create(:tax_household_member, tax_household: tax_household, applicant_id: family_member1.id, is_ia_eligible: true)
    tax_household
  end
  let(:sample_max_aptc_1) {1200}
  let(:sample_csr_percent_1) {87}
  let!(:eligibility_determination) {FactoryBot.create(:eligibility_determination, tax_household: tax_household, max_aptc: sample_max_aptc_1, csr_percent_as_integer: sample_csr_percent_1)}
  let(:product1) {FactoryBot.create(:benefit_markets_products_health_products_health_product, benefit_market_kind: :aca_individual, kind: :health, csr_variant_id: '01', metal_level_kind: :silver)}
  let(:hbx_with_aptc_1) do
    enr = FactoryBot.create(:hbx_enrollment,
                            product: product1,
                            family: family,
                            household: household,
                            is_active: true,
                            aasm_state: 'coverage_selected',
                            changing: false,
                            effective_on: start_on,
                            kind: "individual",
                            applied_aptc_amount: 100,
                            elected_aptc_pct: 0.7)
    FactoryBot.create(:hbx_enrollment_member, applicant_id: family_member1.id, hbx_enrollment: enr)
    enr
  end
  let!(:hbx_enrollments) {[hbx_with_aptc_1]}

  before(:each) do
    allow(::BenefitMarkets::Products::ProductRateCache).to receive(:lookup_rate) {|_id, _start, age| age * 1.0}
    hbx_profile.benefit_sponsorship.benefit_coverage_periods.detect {|bcp| bcp.contains?(start_on)}.update_attributes!(slcsp_id: plan.id)
  end

  context 'return failure with no active tax household' do
    before do
      allow(eligibility_determination).to receive(:tax_household).and_return nil
      input_params = {eligibility_determination: eligibility_determination}
      @result = subject.call(input_params)
    end

    it 'should return monthly aggregate amount' do
      expect(@result.failure).to eq('No active tax household for given eligibility')
    end
  end

  context 'passing params with catastrophic plans' do
    before do
      hbx_with_aptc_1.product.update_attributes(metal_level_kind: 'catastrophic')
      input_params = {eligibility_determination: eligibility_determination}
      @result = subject.call(input_params)
    end

    it 'should return monthly aggregate amount' do
      expect(@result.failure).to eq('Cannot find any enrollments with Non-Catastrophic Plan.')
    end
  end

  context 'apply aggregate on eligible enrollments' do
    before(:each) do
      allow(TimeKeeper).to receive(:date_of_record).and_return Date.new(start_on.year, 1, 26)
      input_params = {eligibility_determination: eligibility_determination}
      allow(family).to receive(:active_household).and_return(household)
      @result = subject.call(input_params)
    end

    it 'returns monthly aggregate amount' do
      expect(@result.success).to eq "Aggregate amount applied on to enrollments"
      expect(family.hbx_enrollments.to_a.first.applied_aptc_amount).not_to eq family.hbx_enrollments.last.applied_aptc_amount
    end
  end
end