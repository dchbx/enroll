require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "change_ce_date_of_termination")

describe ChangeCeDateOfTermination do

  describe "given a task name" do
    let(:given_task_name) { "change_ce_date_of_termination" }
    subject { ChangeCeDateOfTermination.new(given_task_name, double(:current_scope => nil)) }

    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe "census employee not in terminated state" do
    subject { ChangeCeDateOfTermination.new("change_ce_date_of_termination", double(:current_scope => nil)) }

    let(:employer_profile) { census_employee.employer_profile }
    let(:employer_profile_id) { employer_profile.id }
    let(:census_employee) { FactoryGirl.create(:census_employee, hired_on: (TimeKeeper.date_of_record - 2.years).to_s) }
    let(:date) { (TimeKeeper.date_of_record - 2.days).to_s }

    before :each do
      allow(ENV).to receive(:[]).with('ssn').and_return census_employee.ssn
      allow(ENV).to receive(:[]).with('date_of_terminate').and_return date
      census_employee.aasm_state = "employment_terminated"
      census_employee.save
      subject.migrate
      census_employee.reload
    end
    it "should not change dot of ce not in employment termination state" do
      expect(census_employee.employment_terminated_on.to_s).to eq date
    end
  end

  describe "census employee's in terminated state" do
    subject { ChangeCeDateOfTermination.new("termiante_census_employee", double(:current_scope => nil)) }

    let(:employer_profile) { census_employee.employer_profile }
    let(:employer_profile_id) { employer_profile.id }
    let(:date) {  (TimeKeeper::date_of_record - 1.days).to_s }
    let(:census_employee) { FactoryGirl.create(:census_employee, hired_on: (TimeKeeper.date_of_record - 2.days)) }

    before :each do
      allow(ENV).to receive(:[]).with('ssn').and_return census_employee.ssn
      allow(ENV).to receive(:[]).with('date_of_terminate').and_return date
      census_employee.aasm_state = "employment_terminated"
      census_employee.save
      subject.migrate
      census_employee.reload
    end

    it "should change dot of ce not in employment termination state" do
      ce = CensusEmployee.by_ssn(census_employee.ssn).first
      expect(ce.employment_terminated_on.to_s).to eq date
    end
  end
end
