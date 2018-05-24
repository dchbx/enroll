require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "create_employee_role_for_person")

describe CreateEmployeeRoleForPerson, dbclean: :after_each do

  let(:given_task_name) { "create_employee_role_for_person" }
  subject { CreateEmployeeRoleForPerson.new(given_task_name, double(:current_scope => nil)) }

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
        expect(person.employee_roles.count).to eq 0
        subject.migrate
        person.reload
        expect(person.employee_roles.count).to eq 1
      end
    end
  end
end
