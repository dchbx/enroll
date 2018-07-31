require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "update_all_plan_options")

describe UpdateAllPlanOptions, dbclean: :after_each do
  let(:given_task_name) { "plan_offerings" }
  subject { UpdateAllPlanOptions.new(given_task_name, double(:current_scope => nil)) }

  describe "check task name " do
    it "should have given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe "updating the plan attributes" do
    let(:plan) { FactoryGirl.create(:plan, is_horizontal: false, is_vertical: false, is_sole_source: true) }

    it "should update all plans" do
      plan.save!
      subject.migrate
      updated_plan = Plan.all.first
      expect(updated_plan.is_horizontal).to be_truthy
      expect(updated_plan.is_vertical).to be_truthy
      expect(updated_plan.is_sole_source).to be_falsey
    end
  end
end
