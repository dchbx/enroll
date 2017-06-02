require "pry"
require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "update_ce_employment_terminated_on")

describe UpdateCeEmploymentTerminatedOn do

  let(:given_task_name) { "update census employee terminated on" }
  subject { UpdateCeEmploymentTerminatedOn.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end
  describe "change ce's terminated on" do
    let(:census_employee) { FactoryGirl.create(:census_employee, employer_profile_id: plan_year.employer_profile.id)}
    let(:employee_role) { FactoryGirl.create(:employee_role,census_employee:census_employee, employer_profile: plan_year.employer_profile)}
    let(:plan_year) {FactoryGirl.create(:custom_plan_year)}
    before(:each) do
      allow(ENV).to receive(:[]).with("ce_id").and_return(census_employee.id)
      allow(ENV).to receive(:[]).with("new_employment_termination_date").and_return(DateTime.now-3.days)
    end

    it "should change terminated on date" do
      date=Date.strptime((DateTime.now-3.days).to_s, "%m/%d/%Y")
      expect(employee_role.census_employee.employment_terminated_on).to eq nil
      expect(employee_role.census_employee.aasm_state).not_to eq "employment_terminated"
      subject.migrate
      census_employee.reload
      expect(census_employee.employment_terminated_on).to eq date
      expect(census_employee.aasm_state).to eq "employment_terminated"
    end
  end
end
