require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "update_old_enrollments_to_coverage_terminated")

describe UpdateOldEnrollmentsToCoverageTerminated do

  let(:given_task_name) { "update_old_enrollments_to_coverage_terminated" }
  subject { UpdateOldEnrollmentsToCoverageTerminated.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe "changing enrollments state" do
    
    let(:family) { FactoryGirl.create(:family, :with_primary_family_member)}
    let(:hbx_enrollment) { FactoryGirl.create(:hbx_enrollment, household: family.active_household)}
    let(:hbx_enrollment2) { FactoryGirl.create(:hbx_enrollment, household: family.active_household)}
    let(:hbx_enrollment3) { FactoryGirl.create(:hbx_enrollment, household: family.active_household)}

    before(:each) do
      allow(ENV).to receive(:[]).with("hbx_id").and_return(hbx_enrollment.hbx_id)
      allow(ENV).to receive(:[]).with("hbx_id_2").and_return(hbx_enrollment2.hbx_id)
      allow(ENV).to receive(:[]).with("hbx_id_3").and_return(hbx_enrollment3.hbx_id)
    end

    it "should change aasm state to coverage terminated" do
      subject.migrate
      hbx_enrollment.reload
      hbx_enrollment2.reload
      hbx_enrollment3.reload
      expect(hbx_enrollment.aasm_state).to eq "coverage_terminated"
      expect(hbx_enrollment2.aasm_state).to eq "coverage_canceled"
      expect(hbx_enrollment3.hbx_id).to eq hbx_enrollment2.hbx_id
      expect(hbx_enrollment2.plan_id).to eq hbx_enrollment.plan_id
    end
  end
end