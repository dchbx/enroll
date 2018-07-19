require "rails_helper"

describe CompositeRatedPlanCostDecorator, "given:
- a plan
- a benefit group
- a composite rating tier
" do

  let(:plan) { instance_double(Plan) }
  let(:benefit_group) { instance_double(BenefitGroup) }
  let(:composite_rating_tier) { double }
  let(:total_premium_value) { 1234.56 }
  let(:employer_contribution_factor) { 0.65 }
  let(:total_employer_cost) { 802.46 }
  let(:cobra_status) { false }

  subject { CompositeRatedPlanCostDecorator.new(plan, benefit_group, composite_rating_tier, cobra_status) }

  before(:each) do
    allow(benefit_group).to receive(:composite_rating_tier_premium_for).with(composite_rating_tier).and_return(total_premium_value)
    allow(benefit_group).to receive(:composite_employer_contribution_factor_for).with(composite_rating_tier).and_return(employer_contribution_factor)
  end

  it "calculates the correct total premium for that rating tier" do
    expect(subject.total_premium).to eq(total_premium_value)
  end

  it "calculates the correct employer contribution for that rating tier" do
    expect(subject.total_employer_contribution).to eq(total_employer_cost)
  end

  it "calculates the correct total employee cost for that rating tier" do
    expect(subject.total_employee_cost).to eq((subject.total_premium - subject.total_employer_contribution).round(2))
  end

  context "for COBRA employees" do
    let(:cobra_status) { true }

    it "calculates the correct employer contribution for that rating tier" do
      expect(subject.total_employer_contribution).to eq(0.00)
    end

    it "calculates the correct total employee cost for that rating tier" do
      expect(subject.total_employee_cost).to eq((subject.total_premium).round(2))
    end
  end
end
