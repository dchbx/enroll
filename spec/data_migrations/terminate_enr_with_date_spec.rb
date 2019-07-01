require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "terminate_enr_with_date")

describe TerminateEnrWithDate do

  let(:given_task_name) { "terminate_enr_with_date" }
  subject { TerminateEnrWithDate.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe "terminate enrollment with terminated on date" do
    let(:person) { FactoryBot.create(:person, :with_family) }
    let(:family) { person.primary_family }
    let(:hbx_enrollment) { FactoryBot.create(:hbx_enrollment, family: family, effective_on: Date.strptime("02/01/2017" , "%m/%d/%Y"), household: family.active_household)}

    it "should terminate the enrollment with given terminated on date" do
      ClimateControl.modify enr_hbx_id: hbx_enrollment.hbx_id, termination_date: "02/28/2017" do 
        expect(family.active_household.hbx_enrollments).to include hbx_enrollment
        expect(hbx_enrollment.effective_on.to_s).to eq "02/01/2017"
        expect(hbx_enrollment.terminated_on).to eq nil
        expect(hbx_enrollment.aasm_state).to eq "coverage_selected"
        subject.migrate
        hbx_enrollment.reload
        expect(hbx_enrollment.terminated_on.to_s).to eq "02/28/2017"
        expect(hbx_enrollment.aasm_state).to eq "coverage_terminated"
      end
    end
  end
end
