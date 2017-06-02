require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "cancel_policy")

describe CancelPolicy do

  let(:given_task_name) { "cancel_policy" }
  subject { CancelPolicy.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe "changing aasm state" do
    
    let(:family) { FactoryGirl.create(:family, :with_primary_family_member)}
    let(:hbx_enrollment) { FactoryGirl.create(:hbx_enrollment, household: family.active_household)}

    before(:each) do
      allow(ENV).to receive(:[]).with("hbx_id").and_return(hbx_enrollment.hbx_id)
    end

    it "should change aasm state to canceled" do
      subject.migrate
      hbx_enrollment.reload
      expect(hbx_enrollment.aasm_state).to eq "coverage_canceled"
    end
  end
end