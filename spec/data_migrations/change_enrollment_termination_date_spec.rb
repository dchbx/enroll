require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "change_enrollment_termination_date")

describe ChangeEnrollmentTerminationDate, dbclean: :after_each do

  let(:given_task_name) { "change_enrollment_effective_on_date" }
  subject { ChangeEnrollmentTerminationDate.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe "changing enrollment termiantion date" do
    let(:family) { FactoryGirl.create(:family, :with_primary_family_member)}
    let(:hbx_enrollment) { FactoryGirl.create(:hbx_enrollment,terminated_on:Date.today,household: family.active_household)}
    before(:each) do
      allow(ENV).to receive(:[]).with("hbx_id").and_return(hbx_enrollment.hbx_id)
      allow(ENV).to receive(:[]).with("new_termination_date").and_return(hbx_enrollment.terminated_on + 1.month)
    end

    it "should change effective on date" do
      terminated_on = hbx_enrollment.terminated_on
      subject.migrate
      hbx_enrollment.reload
      expect(hbx_enrollment.terminated_on).to eq terminated_on + 1.month
    end
  end
  describe "changing enrollment member's termiantion date" do
    let(:family) { FactoryGirl.create(:family, :with_primary_family_member)}
    let(:hbx_enrollment) { FactoryGirl.create(:hbx_enrollment,terminated_on:Date.today,household: family.active_household)}
    let!(:hbx_enrollment_member) {FactoryGirl.create(:hbx_enrollment_member,hbx_enrollment:hbx_enrollment,applicant_id: family.family_members.first.id,is_subscriber: true, eligibility_date:Date.today )}
    before(:each) do
      allow(ENV).to receive(:[]).with("hbx_id").and_return(hbx_enrollment.hbx_id)
      allow(ENV).to receive(:[]).with("new_termination_date").and_return(hbx_enrollment.terminated_on + 1.month)
    end

    it "should change effective on date" do
      terminated_on = hbx_enrollment.terminated_on
      subject.migrate
      hbx_enrollment.reload
      expect(hbx_enrollment.hbx_enrollment_members.first.coverage_end_on).to eq terminated_on + 1.month
    end
  end
end
