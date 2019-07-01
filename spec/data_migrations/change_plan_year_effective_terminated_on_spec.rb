require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "change_plan_year_effective_terminated_on")

describe ChangePlanYearEffectiveTerminatedon, dbclean: :after_each do

  let(:given_task_name) { "change_plan_year_effective_terminated_on" }
  subject { ChangePlanYearEffectiveTerminatedon.new(given_task_name, double(:current_scope => nil)) }

  def with_modified_env(options, &block)
    ClimateControl.modify(options, &block)
  end

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe "changing plan year's state" do

    let(:family) { FactoryBot.create(:family, :with_primary_family_member)}
    let(:hbx_enrollment) { FactoryBot.create(:hbx_enrollment, family: family, household: family.active_household)}
    let(:py_env_support) {{hbx_id: hbx_enrollment.hbx_id, new_effective_on: "#{hbx_enrollment.effective_on + 1.month}".to_s, new_terminated_on: "#{TimeKeeper.date_of_record}"}}

    it "should change effective on date" do
      effective_on = hbx_enrollment.effective_on
      terminated_on = TimeKeeper.date_of_record
      with_modified_env py_env_support do
        subject.migrate
        hbx_enrollment.reload
        expect(hbx_enrollment.reload.effective_on).to eq effective_on + 1.month
        expect(TimeKeeper.date_of_record).to eq terminated_on
      end
    end
  end
end
