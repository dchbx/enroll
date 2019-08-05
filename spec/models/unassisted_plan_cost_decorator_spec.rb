require 'rails_helper'

RSpec.describe UnassistedPlanCostDecorator, dbclean: :after_each do
  let!(:default_plan)            { double("Product", id: "default_plan_id", kind: "health") }
  let!(:dental_plan)             { double('Product', id: 'dental_plan_id', kind: :dental) }
  let(:plan_cost_decorator)     { UnassistedPlanCostDecorator.new(plan, member_provider) }
  context "rating a large family" do
    let(:plan)            {default_plan}
    let!(:member_provider) {double("member_provider", effective_on: 10.days.ago, hbx_enrollment_members: [father, mother, one, two, three, four, five])}
    let!(:father)          {double("father", dob: 55.years.ago, age_on_effective_date: 55, employee_relationship: "self")}
    let!(:mother)          {double("mother", dob: 45.years.ago, age_on_effective_date: 45, employee_relationship: "spouse")}
    let!(:one)             {double("one"   , dob: 20.years.ago, age_on_effective_date: 20, employee_relationship: "child")}
    let!(:two)             {double("two"   , dob: 18.years.ago, age_on_effective_date: 18, employee_relationship: "child")}
    let!(:three)           {double("three" , dob: 13.years.ago, age_on_effective_date: 13, employee_relationship: "child")}
    let!(:four)            {double("four"  , dob: 11.years.ago, age_on_effective_date: 11, employee_relationship: "child")}
    let!(:five)            {double("five"  , dob: 4.years.ago , age_on_effective_date: 4, employee_relationship: "child")}
    let!(:relationship_benefit_for) do
      {
        "self"   => double("self", :offered? => true),
        "spouse" => double("spouse", :offered? => true),
        "child"  => double("child", :offered? => true)
      }
    end

    before do
      allow(::BenefitMarkets::Products::ProductRateCache).to receive(:lookup_rate) {|_id, _start, age| age * 1.0}
    end

    it "should be possible to construct a new plan cost decorator" do
      expect(plan_cost_decorator.class).to be UnassistedPlanCostDecorator
    end

    it "should have a premium for father" do
      expect(plan_cost_decorator.premium_for(father)).to eq 55.0
    end

    it "should have a premium for mother" do
      expect(plan_cost_decorator.premium_for(mother)).to eq 45.0
    end

    it "should have a premium for one" do
      expect(plan_cost_decorator.premium_for(one)).to eq 20.0
    end

    it "should have a premium for two" do
      expect(plan_cost_decorator.premium_for(two)).to eq 18.0
    end

    it "should have a premium for three" do
      expect(plan_cost_decorator.premium_for(three)).to eq 13.0
    end

    it "should have no premium for four" do
      expect(plan_cost_decorator.premium_for(four)).to eq 0.0
    end

    it "should have no premium for five" do
      expect(plan_cost_decorator.premium_for(five)).to eq 0.0
    end

    it "should have the right total premium" do
      expect(plan_cost_decorator.total_premium).to eq [55, 45, 20, 18, 13].sum
    end

    context "with a dental plan" do
      let(:plan)            {dental_plan}
      it "should have a premium for four" do
        expect(plan_cost_decorator.premium_for(four)).to eq 11.0
      end

      it "should have a premium for five" do
        expect(plan_cost_decorator.premium_for(five)).to eq 4.0
      end

      it "should have the right total premium" do
        expect(plan_cost_decorator.total_premium).to eq [55, 45, 20, 18, 13, 11, 4].sum
      end
    end
  end

  describe 'UnassistedPlanCostDecorator' do
    let!(:family10) { FactoryBot.create(:family, :with_primary_family_member_and_dependent) }
    let!(:member2_age_update) {family10.dependents.first.person.update_attributes(dob: 14.years.ago)}
    let!(:hbx_enrollment10) { FactoryBot.create(:hbx_enrollment, family: family10, household: family10.active_household, aasm_state: 'shopping', product: product) }
    let!(:hbx_enrollment_member1) { FactoryBot.create(:hbx_enrollment_member, applicant_id: family10.primary_applicant.id, is_subscriber: true, eligibility_date: (TimeKeeper.date_of_record - 10.days), hbx_enrollment: hbx_enrollment10) }
    let!(:hbx_enrollment_member2) { FactoryBot.create(:hbx_enrollment_member, applicant_id: family10.family_members[1].id, eligibility_date: (TimeKeeper.date_of_record - 10.days), hbx_enrollment: hbx_enrollment10) }
    let(:product) { FactoryBot.create(:benefit_markets_products_health_products_health_product) }
    let!(:tax_household10) { FactoryBot.create(:tax_household, household: family10.active_household) }
    let!(:eligibility_determination) { FactoryBot.create(:eligibility_determination, tax_household: tax_household10) }
    let!(:tax_household_member1) { tax_household10.tax_household_members.create(applicant_id: family10.primary_applicant.id, is_subscriber: true, is_ia_eligible: true)}
    let!(:tax_household_member2) {tax_household10.tax_household_members.create(applicant_id: family10.family_members[1].id, is_ia_eligible: true)}
    let!(:hbx_profile) { FactoryBot.create(:hbx_profile, :open_enrollment_coverage_period) }
    #let(:plan) { FactoryBot.create(:plan, :with_premium_tables, market: 'individual', metal_level: 'gold', csr_variant_id: '01', active_year: TimeKeeper.date_of_record.year, hios_id: "11111111122302-01") }

    before do
      hbx_profile.benefit_sponsorship.benefit_coverage_periods.detect {|bcp| bcp.contains?(TimeKeeper.datetime_of_record)}.update_attributes!(slcsp_id: product.id)
    end

    context 'for aptc_amount' do
      let(:unassisted_plan_cost_decorator1) { UnassistedPlanCostDecorator.new(product, hbx_enrollment10, 100.00, tax_household10) }
      let(:unassisted_plan_cost_decorator2) { UnassistedPlanCostDecorator.new(product, hbx_enrollment10) }

      before :each do
        allow(unassisted_plan_cost_decorator1).to receive(:premium_for).and_return(200.00)
      end

      it 'should return some valid amount when valid information is given' do
        expect(unassisted_plan_cost_decorator1.aptc_amount(hbx_enrollment_member1)).to eq 50.00
      end

      it 'should return 0.00 when invalid information is given' do
        expect(unassisted_plan_cost_decorator2.aptc_amount(hbx_enrollment_member1)).to eq 0.00
      end
    end

    context 'large_family_factor for dental kind' do
      let!(:dental_product) { FactoryBot.create(:benefit_markets_products_dental_products_dental_product, :with_issuer_profile) }
      let!(:hbx_enrollment10) { FactoryBot.create(:hbx_enrollment, family: family10, household: family10.active_household, aasm_state: 'shopping', product: dental_product) }
      let!(:hbx_enrollment_member1) { FactoryBot.create(:hbx_enrollment_member, applicant_id: family10.primary_applicant.id, is_subscriber: true, eligibility_date: (TimeKeeper.date_of_record - 10.days), hbx_enrollment: hbx_enrollment10) }
      let!(:hbx_enrollment_member2) { FactoryBot.create(:hbx_enrollment_member, applicant_id: family10.family_members[1].id, eligibility_date: (TimeKeeper.date_of_record - 10.days), hbx_enrollment: hbx_enrollment10) }
      let(:unassisted_plan_cost_decorator_dental) { UnassistedPlanCostDecorator.new(dental_product, hbx_enrollment10) }

      it 'should return 1 for dental kind' do
        expect(unassisted_plan_cost_decorator_dental.large_family_factor(hbx_enrollment_member1)).to eq 1
      end
    end
  end
end
