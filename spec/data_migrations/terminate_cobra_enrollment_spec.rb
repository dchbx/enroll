require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "terminate_cobra_enrollment")

describe TerminateCobraEnrollment, dbclean: :after_each do

  let(:given_task_name) { "terminate_cobra_enrollment" }
  subject { TerminateCobraEnrollment.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe "migrate " do
    let(:census_employee) { FactoryGirl.create(:census_employee)}
    let(:family) { FactoryGirl.create(:family, :with_primary_family_member)}
    let(:benefit_group_assignment) { FactoryGirl.build(:benefit_group_assignment)}
    let(:hbx_enrollment) { FactoryGirl.create(:hbx_enrollment,terminated_on:Date.today, household: family.active_household)}
    before(:each) do
      allow(CensusEmployee).to receive(:where).and_return([census_employee])
      allow(census_employee).to receive(:active_and_renewing_benefit_group_assignments).and_return([benefit_group_assignment])
      allow(benefit_group_assignment).to receive(:hbx_enrollment).and_return(hbx_enrollment)
    end

    it "should change aasm_state to coverage_termination_pending" do
      subject.migrate
      expect(hbx_enrollment.aasm_state).to eq "coverage_termination_pending"
    end
  end
  
end
