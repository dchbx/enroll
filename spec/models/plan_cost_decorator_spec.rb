require 'rails_helper'

RSpec.describe PlanCostDecorator, dbclean: :after_each do
  let!(:plan_year)               { double("PlanYear", start_on: Date.today.beginning_of_year) }
  let!(:default_benefit_group)   { instance_double(BenefitGroup, plan_year: plan_year) }  
  let!(:benefit_group)   {default_benefit_group}
  let!(:member_provider) {double("member_provider", class: HbxEnrollment, hbx_enrollment_members: [father, mother, one, two, three, four, five])}
  let!(:father)          {double("father", dob: 55.years.ago, age_on: 55, employee_relationship: "self")}
  let!(:mother)          {double("mother", dob: 45.years.ago, age_on: 45, employee_relationship: "spouse")}
  let!(:one)             {double("one"   , dob: 20.years.ago, age_on: 20, employee_relationship: "child")}
  let!(:two)             {double("two"   , dob: 18.years.ago, age_on: 18, employee_relationship: "child")}
  let!(:three)           {double("three" , dob: 13.years.ago, age_on: 13, employee_relationship: "child")}
  let!(:four)            {double("four"  , dob: 11.years.ago, age_on: 11, employee_relationship: "child")}
  let!(:five)            {double("five"  , dob: 4.years.ago , age_on: 4 , employee_relationship: "child")}
  let!(:relationship_benefit_for) do
    {
      "self"   => double("self", :offered? => true),
      "spouse" => double("spouse", :offered? => true),
      "child"  => double("child", :offered? => true)
    }
  end

  context "rating a large family" do

    context "for health coverage" do 
      let!(:plan) { FactoryGirl.create(:plan, :with_premium_tables, market: 'shop') }
      let!(:reference_plan)  {  FactoryGirl.create(:plan, :with_premium_tables, market: 'shop') }

      let(:plan_cost_decorator)     { PlanCostDecorator.new(plan, member_provider, benefit_group, reference_plan) }

      before do
        allow(benefit_group).to receive(:relationship_benefit_for) {|rel|relationship_benefit_for[rel]}
        allow(benefit_group).to receive(:sic_factor_for).with(plan).and_return(1.0)
        allow(benefit_group).to receive(:sic_factor_for).with(reference_plan).and_return(1.0)
        allow(benefit_group).to receive(:group_size_factor_for).with(plan).and_return(1.0)
        allow(benefit_group).to receive(:group_size_factor_for).with(reference_plan).and_return(1.0)
        # allow for both multi and single rating area cases
        allow(benefit_group).to receive(:rating_area).and_return(double)
        allow(Caches::PlanDetails).to receive(:lookup_rate) {|id, start, age| age * 1.0}
        allow(Caches::PlanDetails).to receive(:lookup_rate_with_area) {|id, start, age, rating_area| age * 1.0}
      end

      it "should be possible to construct a new plan cost decorator" do
        expect(plan_cost_decorator.class).to be PlanCostDecorator
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

      it "round premium contribution of a member" do
        allow(BigDecimal).to receive_message_chain(:new, :round, :to_f).and_return("13.65")
        expect(plan_cost_decorator.premium_for(three)).to eq "13.65"
      end
    end

    context "for dental coverage" do 

      let!(:plan) { FactoryGirl.create(:plan, :with_dental_coverage, :with_premium_tables, market: 'shop') }
      let!(:reference_plan)  {  FactoryGirl.create(:plan, :with_dental_coverage, :with_premium_tables, market: 'shop') }

      let(:plan_cost_decorator)     { PlanCostDecorator.new(plan, member_provider, benefit_group, reference_plan) }

      before do
        allow(benefit_group).to receive(:dental_relationship_benefit_for) {|rel|relationship_benefit_for[rel]}
        allow(benefit_group).to receive(:relationship_benefit_for) {|rel|relationship_benefit_for[rel]}
        allow(benefit_group).to receive(:sic_factor_for).with(plan).and_return(1.0)
        allow(benefit_group).to receive(:sic_factor_for).with(reference_plan).and_return(1.0)
        allow(benefit_group).to receive(:group_size_factor_for).with(plan).and_return(1.0)
        allow(benefit_group).to receive(:group_size_factor_for).with(reference_plan).and_return(1.0)
        # allow for both multi and single rating area cases
        allow(benefit_group).to receive(:rating_area).and_return(double)
        allow(Caches::PlanDetails).to receive(:lookup_rate) {|id, start, age| age * 1.0}
        allow(Caches::PlanDetails).to receive(:lookup_rate_with_area) {|id, start, age, rating_area| age * 1.0}
      end

      it "should be possible to construct a new plan cost decorator" do
        expect(plan_cost_decorator.class).to be PlanCostDecorator
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

      it "should have a premium for four" do
        expect(plan_cost_decorator.premium_for(four)).to eq 11.0
      end

      it "should have a premium for five" do
        expect(plan_cost_decorator.premium_for(five)).to eq 4.0
      end

      it "should have the right total premium" do
        expect(plan_cost_decorator.total_premium).to eq [55, 45, 20, 18, 13, 11, 4].sum
      end

      it "round premium contribution of a member" do
        allow(BigDecimal).to receive_message_chain(:new, :round, :to_f).and_return("13.65")
        expect(plan_cost_decorator.premium_for(three)).to eq "13.65"
      end
    end
  end
end
