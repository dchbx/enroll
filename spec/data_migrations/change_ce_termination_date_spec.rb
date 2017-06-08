require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "change_ce_termination_date")
describe ChangeCeTerminationDate do
  describe "given a task name" do
    let(:given_task_name) { "change_ce_date_of_termination" }
    subject {ChangeCeTerminationDate.new(given_task_name, double(:current_scope => nil)) }
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end
  describe "census employee not in terminated state" do
    subject {ChangeCeTerminationDate.new("termiante_census_employee", double(:current_scope => nil)) }
    let(:employer_profile){ FactoryGirl.create(:employer_profile) }
    let(:employer_profile_id){ employer_profile.id }
    let(:census_employee){ FactoryGirl.create(:census_employee, employer_profile_id: employer_profile.id, employment_terminated_on: TimeKeeper::date_of_record - 5.days, hired_on: "2014-11-11") }
    let(:census_employee_params) {
      {
          "hired_on" => "05/02/2015",
          "employer_profile_id" => employer_profile_id
      }
    }


    let(:date) { TimeKeeper.date_of_record.next_month.beginning_of_month + 2.days }
    let(:date1){TimeKeeper.date_of_record - 5.days}
    before :each do
      allow(ENV).to receive(:[]).with('ssn').and_return census_employee.ssn
      allow(ENV).to receive(:[]).with('date_of_termination').and_return date
      census_employee.aasm_state="employee_termination_pending"
      census_employee.save!
      subject.migrate
      census_employee.reload
    end
    it "should change ce into terminated state with the given termination date" do
      expect(census_employee.aasm_state).to eq "employment_terminated"
      expect(census_employee.employment_terminated_on).to eq date
    end
  end

  describe "census employee's in terminated state" do
    subject {ChangeCeTerminationDate.new("termiante_census_employee", double(:current_scope => nil)) }
    let(:employer_profile) { FactoryGirl.create(:employer_profile) }
    let(:employer_profile_id) { employer_profile.id }
    let(:census_employee) { FactoryGirl.create(:census_employee, employer_profile_id: employer_profile.id,employment_terminated_on: TimeKeeper::date_of_record - 5.days, hired_on: "2014-11-11") }
    let(:census_employee_params) {
      {
          "hired_on" => "05/02/2015",
          "employer_profile_id" => employer_profile_id}
    }
    let(:date) {TimeKeeper::date_of_record - 1.days }
    before :each do
      allow(ENV).to receive(:[]).with('ssn').and_return census_employee.ssn
      allow(ENV).to receive(:[]).with('date_of_termination').and_return date
      census_employee.aasm_state="employment_terminated"
      census_employee.save
      subject.migrate
      census_employee.reload
    end
    it "should not change dot of ce not in employment termination state" do
      ce=CensusEmployee.by_ssn(census_employee.ssn).first
      expect(ce.employment_terminated_on).to eq TimeKeeper::date_of_record - 1.days
    end
  end
end