require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "adding_employee_role")

describe AddingEmployeeRole, dbclean: :after_each do

  let(:given_task_name) { "adding_employee_role" }
  subject { AddingEmployeeRole.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe "creating new employee role", dbclean: :after_each do

    let(:person) { FactoryGirl.create(:person, ssn: "009998887")}
    let(:census_employee) { FactoryGirl.create(:census_employee, first_name: person.first_name, last_name: person.last_name,
      gender: person.gender, ssn: person.ssn, aasm_state: "eligible")}
    let(:employer_profile) { FactoryGirl.create(:employer_profile)}

    before(:each) do
      census_employee.update_attribute(:employer_profile_id, employer_profile.id)
      allow(ENV).to receive(:[]).with('ce_id').and_return(census_employee.id)
      allow(ENV).to receive(:[]).with('person_id').and_return(person.id)
    end

    context "employee without an employee role" do

      it "should link employee role" do
        expect(census_employee.employee_role).to eq nil
        subject.migrate
        census_employee.reload
        expect(census_employee.employee_role).not_to eq nil
      end
    end
  end
end
