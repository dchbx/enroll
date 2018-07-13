require 'rails_helper'

RSpec.describe "employers/plan_years/plan_selection/_plan_details.html.erb" do

  let(:employer_profile){
    instance_double(
      "EmployerProfile",
      legal_name: "legal name llc"
      )
  }

  let(:carrier_profile){
    instance_double(
      "CarrierProfile",
      legal_name: "cp 1"
      )
  }

  let(:health_plan){
    instance_double(
      "Plan",
      name: "my health plan",
      plan_type: "ppo",
      carrier_profile: carrier_profile,
      metal_level: "bronze",
      coverage_kind: "health",
      network_information: "This is a plan",
      active_year: 2016,
      nationwide: true
      )
  }

  let(:dental_plan){
    instance_double(
      "Plan",
      name: "my dental plan",
      plan_type: "ppo",
      carrier_profile: carrier_profile,
      metal_level: "high",
      coverage_kind: "dental",
      network_information: "This is a plan",
      active_year: 2016,
      dental_level: "high",
      nationwide: true
      )
  }

  before :each do
    assign :employer_profile, employer_profile
  end

  context "for health" do

    before :each do
      assign :plan, health_plan
      render partial: "employers/plan_years/plan_selection/plan_details"
    end

    it "should have view plan summary link" do
      expect(rendered).to match /View Plan Summary/
    end

    it "should have health plan summary info" do
      expect(rendered).to match /#{health_plan.plan_type}/i
      expect(rendered).to match /#{health_plan.metal_level}/i
    end

    it "should have note during plan selection" do
      expect(rendered).to have_css("span.glyphicon.glyphicon-info-sign")
      expect(rendered).to have_selector('p', text:"Note: Your final monthly cost is based on")
      expect(rendered).to match /Note: Your final monthly cost is based on final employee enrollment./
    end
  end

  context "for dental" do

    before :each do
      assign :plan, dental_plan
      render partial: "employers/plan_years/plan_selection/plan_details"
    end

    it "should have health plan summary info" do
      expect(rendered).to match /#{dental_plan.plan_type}/i
      expect(rendered).to match /#{dental_plan.metal_level}/i
    end
  end

end
