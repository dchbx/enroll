require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "change_plan_year_effective_date")

describe ChangePlanYearEffectiveDate do

  let(:given_task_name) { "change_plan_year_effective_date" }
  subject { ChangePlanYearEffectiveDate.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe "changing plan year's effective date & reference plan and force publishing the plan year", dbclean: :after_each do

    let(:plan_year) { FactoryGirl.create(:future_plan_year, aasm_state: "draft") }
    let(:benefit_group) { FactoryGirl.create(:benefit_group, plan_year: plan_year)}
    let(:plan) { FactoryGirl.create(:plan, :with_premium_tables) }

    before(:each) do
      allow(ENV).to receive(:[]).with("fein").and_return(plan_year.employer_profile.parent.fein)
      allow(ENV).to receive(:[]).with("aasm_state").and_return(plan_year.aasm_state)
      allow(ENV).to receive(:[]).with("py_new_start_on").and_return(plan_year.start_on - 1.month)
      allow(ENV).to receive(:[]).with("referenece_plan_hios_id").and_return(plan.hios_id)
      allow(ENV).to receive(:[]).with("ref_plan_active_year").and_return(plan.active_year)
      allow(benefit_group).to receive(:elected_plans_by_option_kind).and_return [plan]
    end

    it "should change the plan year effective on date" do
      start_on = plan_year.start_on
      expect(start_on).to eq (TimeKeeper.date_of_record + 2.months).beginning_of_month
      subject.migrate
      plan_year.reload
      expect(plan_year.start_on).to eq start_on - 1.month
    end

    it "should change the reference plan" do
      subject.migrate
      plan_year.reload
      expect(plan_year.benefit_groups.first.reference_plan.hios_id).to eq plan.hios_id
    end

    it "should publish the plan year" do
      subject.migrate
      plan_year.reload
      expect(plan_year.aasm_state).not_to eq "draft"
    end
  end
end
