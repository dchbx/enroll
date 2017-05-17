require 'rails_helper'

RSpec.describe UnassistedPlanCostDecorator, dbclean: :after_each do
  let!(:default_plan)            { double("Plan", id: "default_plan_id", coverage_kind: "health") }
  let!(:dental_plan)             { double("DentalPlan", id: "dental_plan_id", coverage_kind: "dental") }
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
      allow(Caches::PlanDetails).to receive(:lookup_rate) {|id, start, age| age * 1.0}
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
end
