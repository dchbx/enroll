require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "update_ee_dependent_ssn")

describe UpdateEeDependentSSN, dbclean: :after_each do

  let(:given_task_name) { "update_ee_dependent_ssn" }
  subject { UpdateEeDependentSSN.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe "update census dependent ssn" do
    let(:census_employee)  { FactoryGirl.create(:census_employee)}
    let(:census_dependent) { CensusDependent.new(first_name:'David', last_name:'Henry', ssn: "", employee_relationship: "spouse", dob: TimeKeeper.date_of_record - 30.years, gender: "male") }

    before(:each) do
      allow(ENV).to receive(:[]).with("ce_id").and_return(census_employee.id)
      allow(ENV).to receive(:[]).with("dep_id").and_return(census_dependent.id)
      allow(ENV).to receive(:[]).with("dep_ssn").and_return(census_dependent.ssn)
    end

    it "should be valid" do
      expect(census_employee.valid?).to be_truthy
    end

    it "if census_dependents are present" do
      census_employee.census_dependents = [census_dependent]
      expect(census_employee.census_dependents.present?).to be_truthy
    end

    it "if census_dependents are not present" do
      expect(census_employee.census_dependents.present?).to be_falsey
    end

    it "if given dependent is not found" do
      census_employee.census_dependents = []
      expect(census_employee.census_dependents.first).to be_falsey
    end

    it "allow dependent ssn's to be updated to nil" do
      census_employee.census_dependents = [census_dependent]
      subject.migrate
      census_employee.reload
      expect(census_employee.census_dependents.first.ssn).to match(nil)
    end

    it "allow dependent ssn's to be updated" do
      census_employee.census_dependents = [census_dependent]
      census_employee.census_dependents.first.update_attributes!(ssn: "123456789")
      subject.migrate
      census_employee.reload
      expect(census_employee.census_dependents.first.ssn).to match("123456789")
    end
  end
end
