require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "update_carefirst_shop_health_plan_deductible")

describe UpdateCarefirstShopHealthPlanDeductible, dbclean: :after_each do
  subject { UpdateCarefirstShopHealthPlanDeductible.new("update_carefirst_shop_health_plan_deductible", double(current_scope: nil)) }
  let(:plan){ FactoryGirl.create(:plan, name: "BluePreferred PPO HSA/HRA Silver 2000", active_year: 2017) }

  it "should update the plan deductible" do
    plan
    subject.migrate
    plan.reload
    expect(plan.active_year).to eq 2017
    expect(plan.name).to eq "BluePreferred PPO HSA/HRA Silver 2000"
    expect(plan.deductible).to eq "$2,000"
    expect(plan.family_deductible).to eq "$2000 per person | $4000 per group"
  end
end
