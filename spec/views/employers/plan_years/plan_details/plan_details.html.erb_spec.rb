require 'rails_helper'

RSpec.describe "employers/plan_years/plan_selection/_plan_details.html.erb" do

  class AcaHelperModStubber
    extend Config::AcaHelper
  end

  let(:employer_profile){
    instance_double(
      "EmployerProfile",
      legal_name: "legal name llc"
      )
  }

  def new_plan
    double(
      "Plan",
      title: "My Silly Plan",
      name: "plan name",
      carrier_profile: double(legal_name: "legal")
    )
  end

  def plan_cost_decorator
    double(
      "PlanCostDecorator",
      title: new_plan.title,
      premium_for: double("premium_for"),
      employer_contribution_for: double("employer_contribution_for"),
      employee_cost_for: double("employee_cost_for"),
      total_premium: double("total_premium"),
      total_employer_contribution: double("total_employer_contribution"),
      total_employee_cost: double("total_employee_cost"),
      issuer_profile: double(legal_name: "carefirst BCBS"),
      metal_level: "Silver",
      coverage_kind: "health",
      kind: "health",
      name: new_plan.name,
      metal_level_kind: 'metal level kind',
      plan_type: "plan type",
      network_information: "network_information",
      carrier_profile: double(legal_name: "legal")
    )
  end

  def dental_plan
    double(
      "Plan",
      title: "My Silly Plan",
      name: "plan name",
      carrier_profile: double(legal_name: "legal")
    )
  end

  def plan_cost_decorator_dental
    double(
      "PlanCostDecorator",
      title: dental_plan.title,
      premium_for: double("premium_for"),
      employer_contribution_for: double("employer_contribution_for"),
      employee_cost_for: double("employee_cost_for"),
      total_premium: double("total_premium"),
      total_employer_contribution: double("total_employer_contribution"),
      total_employee_cost: double("total_employee_cost"),
      issuer_profile: double(legal_name: "carefirst BCBS"),
      metal_level: "Gold",
      coverage_kind: "dental",
      kind: "health",
      name: new_plan.name,
      metal_level_kind: "Gold",
      plan_type: "plan type",
      network_information: "network_information",
      carrier_profile: double(legal_name: "legal")
    )
  end

  before :each do
    assign :employer_profile, employer_profile

  end

  context "for health" do

    before :each do
      @plan = plan_cost_decorator
      allow(@plan).to receive(:nationwide).and_return(true) if AcaHelperModStubber.offers_nationwide_plans?
      render partial: "employers/plan_years/plan_selection/plan_details"
    end

    it "should have view plan summary link" do
      expect(rendered).to match /View Plan Summary/
    end

    it "should have health plan summary info" do
      expect(rendered).to match /#{ @plan.plan_type}/i
      expect(rendered).to match /#{ @plan.metal_level_kind}/i
    end

    it "should have note during plan selection" do
      expect(rendered).to have_css("span.glyphicon.glyphicon-info-sign")
      expect(rendered).to have_selector('p', text:"Note: Your final monthly cost is based on")
      expect(rendered).to match /Note: Your final monthly cost is based on final employee enrollment./
    end
  end

  context "for dental" do

    before :each do
      @plan = plan_cost_decorator_dental
      allow(@plan).to receive(:nationwide).and_return(true) if AcaHelperModStubber.offers_nationwide_plans?
      render partial: "employers/plan_years/plan_selection/plan_details"
    end

    it "should have health plan summary info" do
      expect(rendered).to match /#{@plan.plan_type}/i
      expect(rendered).to match /#{@plan.metal_level_kind}/i
    end
  end
end
