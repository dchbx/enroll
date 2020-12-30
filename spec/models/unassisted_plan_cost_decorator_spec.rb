# frozen_string_literal: true

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
    let!(:one)             {double("one", dob: 20.years.ago, age_on_effective_date: 20, employee_relationship: "child")}
    let!(:two)             {double("two", dob: 18.years.ago, age_on_effective_date: 18, employee_relationship: "child")}
    let!(:three)           {double("three", dob: 13.years.ago, age_on_effective_date: 13, employee_relationship: "child")}
    let!(:four)            {double("four", dob: 11.years.ago, age_on_effective_date: 11, employee_relationship: "child")}
    let!(:five)            {double("five", dob: 4.years.ago, age_on_effective_date: 4, employee_relationship: "child")}
    let!(:relationship_benefit_for) do
      { "self" => double("self", :offered? => true),
        "spouse" => double("spouse", :offered? => true),
        "child" => double("child", :offered? => true)}
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

    let(:person) { FactoryBot.create(:person, :with_consumer_role, :with_active_consumer_role) }
    let!(:family10) { FactoryBot.create(:family, :with_primary_family_member_and_dependent, person: person) }
    let!(:hbx_enrollment10) { FactoryBot.create(:hbx_enrollment, family: family10, household: family10.active_household, aasm_state: 'shopping', product: product, consumer_role_id: person.consumer_role.id, effective_on: TimeKeeper.date_of_record) }
    let!(:hbx_enrollment_member1) { FactoryBot.create(:hbx_enrollment_member, applicant_id: family10.primary_applicant.id, is_subscriber: true, eligibility_date: (TimeKeeper.date_of_record - 10.days), coverage_start_on: TimeKeeper.date_of_record, hbx_enrollment: hbx_enrollment10) }
    let!(:hbx_enrollment_member2) { FactoryBot.create(:hbx_enrollment_member, applicant_id: family10.family_members[1].id, eligibility_date: (TimeKeeper.date_of_record - 10.days), coverage_start_on: TimeKeeper.date_of_record, hbx_enrollment: hbx_enrollment10) }
    let(:product) { FactoryBot.create(:benefit_markets_products_health_products_health_product) }
    let!(:tax_household10) { FactoryBot.create(:tax_household, household: family10.active_household, effective_ending_on: nil) }
    let!(:eligibility_determination) { FactoryBot.create(:eligibility_determination, tax_household: tax_household10, max_aptc: 2000) }
    let!(:tax_household_member1) { tax_household10.tax_household_members.create(applicant_id: family10.primary_applicant.id, is_subscriber: true, is_ia_eligible: true)}
    let!(:tax_household_member2) {tax_household10.tax_household_members.create(applicant_id: family10.family_members[1].id, is_ia_eligible: true)}
    let!(:hbx_profile) { FactoryBot.create(:hbx_profile, :open_enrollment_coverage_period) }
    let(:person2) { family10.family_members[1].person }

    before :each do
      @product = BenefitMarkets::Products::Product.all.where(benefit_market_kind: :aca_individual).first
      @product.update_attributes(ehb: 0.9844)
      premium_table = @product.premium_tables.first
      premium_table.premium_tuples.where(age: 59).first.update_attributes(cost: 814.85)
      premium_table.premium_tuples.where(age: 60).first.update_attributes(cost: 846.72)
      premium_table.premium_tuples.where(age: 61).first.update_attributes(cost: 879.8)
      @product.save!
      hbx_enrollment10.update_attributes(product: @product)
      hbx_profile.benefit_sponsorship.benefit_coverage_periods.each{|bcp| bcp.update_attributes!(slcsp_id: @product.id)}

      allow(::BenefitMarkets::Products::ProductRateCache).to receive(:lookup_rate).with(@product, hbx_enrollment10.effective_on, 59, 'R-DC001').and_return(814.85)
      allow(::BenefitMarkets::Products::ProductRateCache).to receive(:lookup_rate).with(@product, hbx_enrollment10.effective_on, 60, 'R-DC001').and_return(846.72)
      allow(::BenefitMarkets::Products::ProductRateCache).to receive(:lookup_rate).with(@product, hbx_enrollment10.effective_on, 61, 'R-DC001').and_return(879.8)
    end

    context 'for valid arguments' do
      before do
        person.update_attributes!(dob: (hbx_enrollment10.effective_on - 61.years))
        person2.update_attributes!(dob: (hbx_enrollment10.effective_on - 59.years))
      end

      context 'for persisted enrollment object' do
        context 'when elected aptc more than ehb premium, should rounddown on premium' do
          before :each do
            @upcd_1 = UnassistedPlanCostDecorator.new(@product, hbx_enrollment10, 1700.00, tax_household10)
          end

          it 'should return amounts based on member 1 age' do
            expect(@upcd_1.aptc_amount(hbx_enrollment_member1)).to eq 866.07
          end

          it 'should return amounts based on member 2 age' do
            expect(@upcd_1.aptc_amount(hbx_enrollment_member2)).to eq 802.13
          end

          it 'should return total_aptc_amount' do
            expect(@upcd_1.total_aptc_amount).to eq 1668.2
          end
        end

        context 'when elected aptc less than ehb premium, no rounding on premium' do
          before :each do
            @upcd_2 = UnassistedPlanCostDecorator.new(@product, hbx_enrollment10, 1500.00, tax_household10)
          end

          it 'should return amounts based on member 1 age' do
            expect(@upcd_2.aptc_amount(hbx_enrollment_member1)).to eq 778.7465531710825
          end

          it 'should return amounts based on member 2 age' do
            expect(@upcd_2.aptc_amount(hbx_enrollment_member2)).to eq 721.2534468289174
          end

          it 'should return total_aptc_amount' do
            expect(@upcd_2.total_aptc_amount).to eq 1500
          end
        end
      end

      context 'when elected aptc is 0, use method total_ehb_premium' do
        it 'should return total_ehb_premium' do
          upcd = UnassistedPlanCostDecorator.new(@product, hbx_enrollment10, 0.00, tax_household10)
          expect(upcd.total_ehb_premium).to eq 1668.2
        end
      end

      context 'for non-persisted enrollment object' do
        let(:current_date) {TimeKeeper.date_of_record}
        let!(:enrollment1) { FactoryBot.build(:hbx_enrollment, family: family10, household: family10.active_household, aasm_state: 'shopping', product: @product, consumer_role_id: person.consumer_role.id, effective_on: current_date) }
        let!(:enr_member1) { FactoryBot.build(:hbx_enrollment_member, applicant_id: family10.primary_applicant.id, is_subscriber: true, eligibility_date: (TimeKeeper.date_of_record), hbx_enrollment: enrollment1, coverage_start_on: current_date) }
        let!(:enr_member2) { FactoryBot.build(:hbx_enrollment_member, applicant_id: family10.family_members[1].id, eligibility_date: (TimeKeeper.date_of_record), hbx_enrollment: enrollment1, coverage_start_on: current_date) }

        context 'when elected aptc more than ehb premium, should rounddown on premium' do
          before :each do
            @upcd_3 = UnassistedPlanCostDecorator.new(@product, enrollment1, 1700.00, tax_household10)
          end

          it 'should return amounts based on member 1 age' do
            expect(@upcd_3.aptc_amount(enr_member1)).to eq 866.07
          end

          it 'should return amounts based on member 2 age' do
            expect(@upcd_3.aptc_amount(enr_member2)).to eq 802.13
          end

          it 'should return total_aptc_amount' do
            expect(@upcd_3.total_aptc_amount).to eq 1668.2
          end
        end

        context 'when elected aptc less than ehb premium, no rounding on premium' do
          before :each do
            @upcd_4 = UnassistedPlanCostDecorator.new(@product, enrollment1, 1500.00, tax_household10)
          end

          it 'should return amounts based on member 1 age' do
            expect(@upcd_4.aptc_amount(enr_member1)).to eq 778.7465531710825
          end

          it 'should return amounts based on member 2 age' do
            expect(@upcd_4.aptc_amount(enr_member2)).to eq 721.2534468289174
          end

          it 'should return total_aptc_amount' do
            expect(@upcd_4.total_aptc_amount).to eq 1500
          end
        end
      end
    end

    context 'for invalid arguments' do
      let(:unassisted_plan_cost_decorator2) { UnassistedPlanCostDecorator.new(@product, hbx_enrollment10) }

      it 'should return 0.00 when invalid information is given' do
        expect(unassisted_plan_cost_decorator2.aptc_amount(hbx_enrollment_member1)).to eq 0.00
      end
    end

    context 'for uqhp case' do
      before do
        family10.active_household.tax_households.destroy_all
        family10.active_household.reload
      end

      it 'should return 0.00 as this is a uqhp case' do
        unassisted_plan_cost_decorator = UnassistedPlanCostDecorator.new(@product, hbx_enrollment10)
        expect(unassisted_plan_cost_decorator.aptc_amount(hbx_enrollment_member1)).to eq 0.00
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

  describe 'ehb premiums' do
    let(:person) {FactoryBot.create(:person, :with_consumer_role, :with_active_consumer_role)}
    let!(:family10) {FactoryBot.create(:family, :with_primary_family_member_and_dependent, person: person)}
    let!(:hbx_enrollment10) {FactoryBot.create(:hbx_enrollment, family: family10, household: family10.active_household, aasm_state: 'shopping', product: @product, consumer_role_id: person.consumer_role.id)}
    let!(:hbx_enrollment_member1) {FactoryBot.create(:hbx_enrollment_member, applicant_id: family10.primary_applicant.id, is_subscriber: true, eligibility_date: (TimeKeeper.date_of_record - 10.days), hbx_enrollment: hbx_enrollment10)}
    let!(:hbx_enrollment_member2) {FactoryBot.create(:hbx_enrollment_member, applicant_id: family10.family_members[1].id, eligibility_date: (TimeKeeper.date_of_record - 10.days), hbx_enrollment: hbx_enrollment10)}
    let!(:tax_household10) {FactoryBot.create(:tax_household, household: family10.active_household, effective_ending_on: nil)}
    let!(:eligibility_determination) {FactoryBot.create(:eligibility_determination, tax_household: tax_household10, max_aptc: 2000)}
    let!(:tax_household_member1) {tax_household10.tax_household_members.create(applicant_id: family10.primary_applicant.id, is_subscriber: true, is_ia_eligible: true)}
    let!(:tax_household_member2) {tax_household10.tax_household_members.create(applicant_id: family10.family_members[1].id, is_ia_eligible: true)}
    let!(:hbx_profile) {FactoryBot.create(:hbx_profile, :open_enrollment_coverage_period)}
    let(:person2) {family10.family_members[1].person}

    before :each do
      @product = BenefitMarkets::Products::Product.all.where(benefit_market_kind: :aca_individual).first
      @product.update_attributes(ehb: 0.9844)
      premium_table = @product.premium_tables.first
      premium_table.premium_tuples.where(age: 59).first.update_attributes(cost: 814.85)
      premium_table.premium_tuples.where(age: 60).first.update_attributes(cost: 846.72)
      premium_table.premium_tuples.where(age: 61).first.update_attributes(cost: 879.8)
      @product.save!
      hbx_enrollment10.update_attributes(product: @product)
      hbx_profile.benefit_sponsorship.benefit_coverage_periods.each {|bcp| bcp.update_attributes!(slcsp_id: @product.id)}

      allow(::BenefitMarkets::Products::ProductRateCache).to receive(:lookup_rate).with(@product, hbx_enrollment10.effective_on, 59, 'R-DC001').and_return(814.85)
      allow(::BenefitMarkets::Products::ProductRateCache).to receive(:lookup_rate).with(@product, hbx_enrollment10.effective_on, 60, 'R-DC001').and_return(846.72)
      allow(::BenefitMarkets::Products::ProductRateCache).to receive(:lookup_rate).with(@product, hbx_enrollment10.effective_on, 61, 'R-DC001').and_return(879.8)
      person.update_attributes!(dob: (hbx_enrollment10.effective_on - 61.years))
      person2.update_attributes!(dob: (hbx_enrollment10.effective_on - 59.years))
      @upcd_1 = UnassistedPlanCostDecorator.new(@product, hbx_enrollment10, 1700.00, tax_household10)
    end

    context 'for total_ehb_premium' do
      it 'should return some valid amount when valid information is given' do
        expect(@upcd_1.total_ehb_premium).to eq 1668.2
      end
    end

    context 'for member_ehb_premium' do
      it 'should return 0.00 when invalid information is given' do
        expect(@upcd_1.member_ehb_premium(hbx_enrollment_member1)).to eq 866.07512
      end

      it 'should return 0.00 when invalid information is given' do
        expect(@upcd_1.member_ehb_premium(hbx_enrollment_member2)).to eq 802.1383400000001
      end
    end
  end
end