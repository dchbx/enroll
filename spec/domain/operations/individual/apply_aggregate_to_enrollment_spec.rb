# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Operations::Individual::ApplyAggregateToEnrollment do

  subject do
    described_class.new.call(eligibility_determination: params)
  end

  describe "verify APTC calculation for full month enrollments" do
    let!(:start_on) {TimeKeeper.date_of_record.beginning_of_year}
    let!(:family) {FactoryBot.create(:family, :with_primary_family_member)}
    let(:family_member1) {FactoryBot.create(:family_member, family: household.family)}
    let(:family_member2) {FactoryBot.create(:family_member, family: household.family)}
    let!(:household) {FactoryBot.create(:household, family: family)}
    let!(:tax_household) {FactoryBot.create(:tax_household, effective_ending_on: nil, household: family.households.first)}
    let!(:household) { family.active_household}
    let(:sample_max_aptc_1) {1200}
    let(:sample_max_aptc_2) {612.33}
    let(:sample_csr_percent_1) {87}
    let(:sample_csr_percent_2) {94}
    let!(:eligibility_determination) {FactoryBot.create(:eligibility_determination, tax_household: tax_household, max_aptc: sample_max_aptc_1, csr_percent_as_integer: sample_csr_percent_1)}
    let!(:eligibility_determination_2) {FactoryBot.create(:eligibility_determination, determined_at: start_on + 4.months, tax_household: tax_household, max_aptc: sample_max_aptc_2, csr_percent_as_integer: sample_csr_percent_2)}
    let(:product1) {FactoryBot.create(:benefit_markets_products_health_products_health_product, benefit_market_kind: :aca_individual, kind: :health, csr_variant_id: '01', metal_level_kind: :silver)}
    let(:product2) {FactoryBot.create(:benefit_markets_products_health_products_health_product, benefit_market_kind: :aca_individual, kind: :health, csr_variant_id: '01', ehb: 0.9939)}
    # Enrollments
    let!(:hbx_with_aptc_1) do
      hbx = FactoryBot.create(:hbx_enrollment,
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
      hbx.hbx_enrollment_members << FactoryBot.build(:hbx_enrollment_member, applicant_id: family_member1.id, eligibility_date: start_on, applied_aptc_amount: 70)
      hbx.save
    end
    let!(:hbx_with_aptc_2) do
      hbx2 = FactoryBot.create(:hbx_enrollment,
                               product: product2,
                               family: family,
                               household: household,
                               is_active: true,
                               aasm_state: 'coverage_selected',
                               changing: false,
                               effective_on: (start_on + 4.months),
                               kind: "individual",
                               applied_aptc_amount: 210)
      hbx2.hbx_enrollment_members << FactoryBot.build(:hbx_enrollment_member, applicant_id: family_member2.id, eligibility_date: start_on, applied_aptc_amount: 30)
      hbx2.save
    end
    let!(:hbx_enrollments) {[hbx_with_aptc_1, hbx_with_aptc_2]}

    before(:each) do
      allow(::BenefitMarkets::Products::ProductRateCache).to receive(:lookup_rate) {|_id, _start, age| age * 1.0}
    end

    describe "Not passing params to call the operation" do
      let(:params) { { } }

      it "fails" do
        expect(subject).not_to be_success
        expect(subject.failure).to eq "Given object is not a valid eligibility determination object"
      end
    end

    describe "passing params to call the operation without tax household" do
      let(:params) { eligibility_determination }

      before(:each) do
        allow(eligibility_determination).to receive(:tax_household).and_return nil
      end

      it "fails" do
        expect(subject).not_to be_success
        expect(subject.failure).to eq "No active tax household for given eligibility"
      end
    end

    describe "apply aggregate on eligible enrollments" do
      let(:params) { eligibility_determination }

      before(:each) do
        allow(family).to receive(:active_household).and_return(household)
      end

      it "returns monthly aggregate amount" do
        expect(subject.success).to eq "Aggregate amount applied on to enrollments"
      end
    end
  end

  describe "should NOT apply APTC on enrollments with catastrophic plans" do
    let!(:start_on) {TimeKeeper.date_of_record.beginning_of_year}
    let!(:family) {FactoryBot.create(:family, :with_primary_family_member)}
    let!(:household) {FactoryBot.create(:household, family: family)}
    let!(:tax_household) {FactoryBot.create(:tax_household, effective_ending_on: nil, household: family.households.first)}
    let!(:household) { family.active_household}
    let(:sample_max_aptc_1) {1200}
    let(:sample_csr_percent_1) {87}
    let!(:eligibility_determination) {FactoryBot.create(:eligibility_determination, tax_household: tax_household, max_aptc: sample_max_aptc_1, csr_percent_as_integer: sample_csr_percent_1)}
    let(:product1) {FactoryBot.create(:benefit_markets_products_health_products_health_product, benefit_market_kind: :aca_individual, kind: :health, csr_variant_id: '01', metal_level_kind: :catastrophic)}
    let!(:hbx_with_aptc_1) do
      FactoryBot.create(:hbx_enrollment,
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
    end
    let!(:hbx_enrollments) {[hbx_with_aptc_1]}

    describe "passing params with catastrophic plans" do
      let(:params) { eligibility_determination }

      it "fails" do
        expect(subject).not_to be_success
        expect(subject.failure).to eq "Cannot find Non-Catastrophic Plans"
      end
    end
  end
end