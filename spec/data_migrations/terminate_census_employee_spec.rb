require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "terminate_census_employee")

def common_method(object, aasm_state)
  object.aasm_state = aasm_state if aasm_state.present?
  object.save!
  subject.migrate
  object.reload
end

describe TerminateCensusEmployee, dbclean: :after_each do
  subject { TerminateCensusEmployee.new("termiante_census_employee", double(:current_scope => nil)) }
  let(:employer_profile) { FactoryGirl.create(:employer_profile) }
  let(:employer_profile_id) { employer_profile.id }

  context "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql "termiante_census_employee"
    end
  end

  context "census employee's employment_terminated_on with past date" do
    let(:census_employee) { FactoryGirl.create(:census_employee, employer_profile_id: employer_profile.id, employment_terminated_on: TimeKeeper::date_of_record - 5.days, hired_on: "2014-11-11") }

    it "with employee_termination_pending aasm_state" do
      common_method(census_employee, "employee_termination_pending")
      expect(census_employee.aasm_state).to eq "employment_terminated"
    end

    it "with employee_role_linked aasm_state" do
      common_method(census_employee, "employee_role_linked")
      expect(census_employee.aasm_state).to eq "employment_terminated"
    end
  end

  context "census employee's employment_terminated_on with future date" do
    let(:census_employee) { FactoryGirl.create(:census_employee, employer_profile_id: employer_profile.id, hired_on: "2014-11-11") }

    it "census employee termination should be in pending state" do
      census_employee.terminate_employment!(TimeKeeper.date_of_record + 5.days)
      common_method(census_employee, "")
      expect(census_employee.aasm_state).to eq "employee_termination_pending"
    end

    it "should not be terminated when employment_terminated_on is nil" do
      common_method(census_employee, "employee_role_linked")
      expect(census_employee.employment_terminated_on).to eq nil
      expect(census_employee.aasm_state).to eq "employee_role_linked"
    end
  end
end