require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "terminate_census_employee")

describe TerminateCensusEmployee do

  describe "given a task name" do
    let(:given_task_name) { "termiante_census_employee" }
    subject { TerminateCensusEmployee.new(given_task_name, double(:current_scope => nil)) }

    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe "census employee's employment_terminated_on with past date" do
    subject { TerminateCensusEmployee.new("termiante_census_employee", double(:current_scope => nil)) }

    let(:employer_profile) { FactoryGirl.create(:employer_profile) }
    let(:employer_profile_id) { employer_profile.id }
    let(:census_employee) { FactoryGirl.create(:census_employee, employer_profile_id: employer_profile.id, employment_terminated_on: TimeKeeper::date_of_record - 5.days, hired_on: "2014-11-11") }
    let(:census_employee_params) {
      {"first_name" => "aqzz",
       "middle_name" => "",
       "last_name" => "White",
       "gender" => "male",
       "is_business_owner" => true,
       "hired_on" => "05/02/2015",
       "employer_profile_id" => employer_profile_id} }

    before :each do
      census_employee.aasm_state="employee_termination_pending"
      census_employee.save!
      subject.migrate
      census_employee.reload
    end
    it "census employee should termianted" do
      expect(census_employee.aasm_state).to eq "employment_terminated"
    end
  end

  describe "census employee's employment_terminated_on with future date" do
    subject { TerminateCensusEmployee.new("termiante_census_employee", double(:current_scope => nil)) }

    let(:employer_profile) { FactoryGirl.create(:employer_profile) }
    let(:employer_profile_id) { employer_profile.id }
    let(:census_employee) { FactoryGirl.create(:census_employee, employer_profile_id: employer_profile.id, hired_on: "2014-11-11") }
    let(:census_employee_params) {
      {"first_name" => "aqzz",
       "middle_name" => "",
       "last_name" => "White",
       "gender" => "male",
       "is_business_owner" => true,
       "hired_on" => "05/02/2015",
       "employer_profile_id" => employer_profile_id} }
    before :each do
      census_employee.terminate_employment!(TimeKeeper.date_of_record + 5.days)
      subject.migrate
      census_employee.reload
    end
    it "census employee termination should be in pending state" do
      expect(census_employee.aasm_state).to eq "employee_termination_pending"
    end
  end

  describe "terminating census employee's with employee_role_linked and with employment_terminated_on passed current date" do
    subject { TerminateCensusEmployee.new("termiante_census_employee", double(:current_scope => nil)) }

    let(:employer_profile) { FactoryGirl.create(:employer_profile) }
    let(:employer_profile_id) { employer_profile.id }
    let(:census_employee) { FactoryGirl.create(:census_employee, employer_profile_id: employer_profile.id, employment_terminated_on: TimeKeeper::date_of_record - 5.days, hired_on: "2014-11-11") }
    let(:census_employee_params) {
      {"first_name" => "aqzz",
       "middle_name" => "",
       "last_name" => "White",
       "gender" => "male",
       "is_business_owner" => true,
       "hired_on" => "05/02/2015",
       "employer_profile_id" => employer_profile_id} }

    before :each do
      census_employee.aasm_state="employee_role_linked"
      census_employee.save!
      subject.migrate
      census_employee.reload
    end
    it "census employee should termianted" do
      expect(census_employee.aasm_state).to eq "employment_terminated"
    end
  end

  describe "active census employee should not be terminated when no employment_terminated_on date present " do
    subject { TerminateCensusEmployee.new("termiante_census_employee", double(:current_scope => nil)) }

    let(:employer_profile) { FactoryGirl.create(:employer_profile) }
    let(:employer_profile_id) { employer_profile.id }
    let(:census_employee) { FactoryGirl.create(:census_employee, employer_profile_id: employer_profile.id, hired_on: "2014-11-11") }
    let(:census_employee_params) {
      {"first_name" => "aqzz",
       "middle_name" => "",
       "last_name" => "White",
       "gender" => "male",
       "is_business_owner" => true,
       "hired_on" => "05/02/2015",
       "employer_profile_id" => employer_profile_id} }
    before :each do
      census_employee.aasm_state="employee_role_linked"
      census_employee.save!
      subject.migrate
      census_employee.reload
    end
    it "census employee should not be terminated" do
      expect(census_employee.employment_terminated_on).to eq nil
      expect(census_employee.aasm_state).to eq "employee_role_linked"
    end
  end
end
