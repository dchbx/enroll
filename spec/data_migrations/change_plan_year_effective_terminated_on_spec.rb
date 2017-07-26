require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "change_plan_year_effective_terminated_on")

describe ChangePlanYearEffectiveTerminatedon, dbclean: :after_each do

  let(:given_task_name) { "change_plan_year_effective_terminated_on" }
  subject { ChangePlanYearEffectiveTerminatedon.new(given_task_name, double(:current_scope => nil)) }

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
      allow(ENV).to receive(:[]).with("new_terminated_on").and_return(TimeKeeper.date_of_record)
    end

    it "should change effective on date" do
      effective_on = hbx_enrollment.effective_on
      terminated_on = TimeKeeper.date_of_record
      subject.migrate
      hbx_enrollment.reload
      expect(hbx_enrollment.effective_on).to eq effective_on + 1.month
      expect(TimeKeeper.date_of_record).to eq terminated_on
    end
  end
end
