require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "cancel_plan_year")

describe CancelPlanYear do

  let(:given_task_name) { "cancel_plan_year" }
  subject { CancelPlanYear.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe "cancel plan year", dbclean: :after_each do
    let(:benefit_group) { FactoryGirl.create(:benefit_group)}
    let(:plan_year) { FactoryGirl.create(:plan_year, benefit_groups: [benefit_group], aasm_state: "enrolled")}
    let!(:plan_year2) { FactoryGirl.create(:plan_year, aasm_state: "active")}
    let(:family) { FactoryGirl.create(:family, :with_primary_family_member)}
    let!(:enrollment) { FactoryGirl.create(:hbx_enrollment, household: family.active_household, aasm_state: "coverage_enrolled", benefit_group_id: plan_year.benefit_groups.first.id)}
    before(:each) do
      allow(ENV).to receive(:[]).with('plan_year_state').and_return(plan_year.aasm_state)
      allow(ENV).to receive(:[]).with("plan_year_start_on").and_return(plan_year.start_on)
      allow(ENV).to receive(:[]).with('feins').and_return(plan_year.employer_profile.parent.fein)
      subject.migrate
      plan_year.reload
      enrollment.reload
    end

    it "should cancel the plan year" do
      expect(plan_year.aasm_state).to eq "canceled"
      expect(plan_year2.aasm_state).to eq "active"
    end

    it "should cancel the enrollment" do
      expect(enrollment.aasm_state).to eq "coverage_canceled"
    end
  end
end
