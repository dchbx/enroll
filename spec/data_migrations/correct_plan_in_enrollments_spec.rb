require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "correct_plan_in_enrollment")

describe CorrectPlanInEnrollment do

  let(:given_task_name) { "correct_plan_in_enrollment" }
  subject { CorrectPlanInEnrollment.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe "fix_enrollment" do
    
    let(:family) { FactoryGirl.create(:family, :with_primary_family_member)}
    let(:hbx_enrollment) { FactoryGirl.create(:hbx_enrollment, :individual_unassisted, :with_enrollment_members, household: family.active_household) }
    let(:incorrect_plan) { FactoryGirl.create(:plan, hios_id: hbx_enrollment.plan.hios_id, active_year: hbx_enrollment.plan.active_year - 1 ) }
    let(:correct_plan) { hbx_enrollment.plan }

    before(:each) do
      correct_plan = hbx_enrollment.plan
      hbx_enrollment.plan = incorrect_plan
      hbx_enrollment.save!
    end

    it "should change plan to the correct one" do
      expect(subject.fix_enrollment(hbx_enrollment).plan).to eq(correct_plan)
    end
  end
end
