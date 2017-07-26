require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "remove_termination_date_from_enrollment")

describe RemoveTerminationDateFromEnrollment do
  let(:given_task_name) { "remove_termination_date_from_enrollment" }
  subject { RemoveTerminationDateFromEnrollment.new(given_task_name, double(:current_scope => nil)) }
  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end
  describe "remove termination date from enrollment" do
    let(:family) { FactoryGirl.create(:family, :with_primary_family_member)}
    let(:hbx_enrollment) { FactoryGirl.create(:hbx_enrollment, household: family.active_household, terminated_on:DateTime.now())}
    before(:each) do
      allow(ENV).to receive(:[]).with("enrollment_hbx_id").and_return(hbx_enrollment.hbx_id)
    end
    it "should change aasm state to coverage terminated" do
      expect(hbx_enrollment.terminated_on).not_to eq nil
      subject.migrate
      hbx_enrollment.reload
      expect(hbx_enrollment.terminated_on).to eq nil
      expect(hbx_enrollment.aasm_state).to eq "coverage_selected"
    end
  end
end
