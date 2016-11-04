require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "change_enrollment_effective_on_date")

describe ChangeEnrollmentEffectiveOnDate do

  let(:given_task_name) { "change_enrollment_effective_on_date" }
  subject { ChangeEnrollmentEffectiveOnDate.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe "changing plan year's state" do
    
    let(:family) { FactoryGirl.create(:family, :with_primary_family_member)}
    let(:hbx_enrollment) { FactoryGirl.create(:hbx_enrollment, household: family.active_household)}

    before(:each) do
      allow(ENV).to receive(:[]).with("hbx_id").and_return(hbx_enrollment.hbx_id)
      allow(ENV).to receive(:[]).with("new_effective_on").and_return(hbx_enrollment.effective_on + 1.month)
    end

    it "should change effective on date" do
      effective_on = hbx_enrollment.effective_on
      subject.migrate
      hbx_enrollment.reload
      expect(hbx_enrollment.effective_on).to eq effective_on + 1.month
    end
  end
end
