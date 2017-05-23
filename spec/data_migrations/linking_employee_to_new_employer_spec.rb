require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "linking_employee_to_new_employer")

describe LinkingEmployeeToNewEmployer do

  let(:given_task_name) { "linking_employee_to_new_employer" }
  subject { LinkingEmployeeToNewEmployer.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe "creating new employee role" do

    let(:person) { FactoryGirl.create(:person)}
    let(:old_census_employee) { FactoryGirl.create(:census_employee, first_name: person.first_name, last_name: person.last_name,
      gender: person.gender, aasm_state: "eligible", employment_terminated_on: TimeKeeper.date_of_record - 5.days)}
    let(:new_census_employee) { FactoryGirl.create(:census_employee, first_name: person.first_name, last_name: person.last_name, 
      gender: person.gender, aasm_state: "eligible")}
    let(:employee_role) { FactoryGirl.create(:employee_role, census_employee_id: old_census_employee.id, person: person, employer_profile: old_census_employee.employer_profile)}
    let(:plan_year_one) { FactoryGirl.create(:plan_year, employer_profile: old_census_employee.employer_profile, aasm_state: "active")}
    let(:plan_year_two) { FactoryGirl.create(:plan_year, employer_profile: new_census_employee.employer_profile, aasm_state: "active")}
    let!(:benefit_group_assignment)  { FactoryGirl.create(:benefit_group_assignment, benefit_group: benefit_group, census_employee: new_census_employee) }
    let(:benefit_group) { FactoryGirl.create(:benefit_group, plan_year: plan_year_two) }

    before(:each) do
      allow(ENV).to receive(:[]).with("old_census_employee_id").and_return(old_census_employee.id)
      allow(ENV).to receive(:[]).with("new_census_employee_id").and_return(new_census_employee.id)
      allow(ENV).to receive(:[]).with("person_id").and_return(person.id)
      allow_any_instance_of(CensusEmployee).to receive(:assign_default_benefit_package).and_return(nil)
      old_census_employee.update_attributes(employee_role_id: employee_role.id, ssn: new_census_employee.ssn, dob: new_census_employee.dob)
      person.update_attributes(ssn: new_census_employee.ssn, dob: new_census_employee.dob)
    end

    context "without an employee role for new census record" do

      it "should build a new employee role record for new census record", dbclean: :after_each do
        expect(new_census_employee.employee_role).to eq nil
        subject.migrate
        new_census_employee.reload
        expect(new_census_employee.employee_role).not_to eq nil
      end

      it "should change old census employee state", dbclean: :after_each do
        old_census_employee.update_attribute(:aasm_state, "employee_role_linked")
        subject.migrate
        old_census_employee.reload
        expect(old_census_employee.aasm_state).to eq "employment_terminated"
      end

      it "should not terminate census record if DOT > today" do
        old_census_employee.update_attributes(employment_terminated_on: TimeKeeper.date_of_record + 5.days, aasm_state: "employee_role_linked")
        subject.migrate
        old_census_employee.reload
        expect(old_census_employee.aasm_state).to eq "employee_role_linked"
      end
    end

    context "with an existing employee role for new census record" do

      let!(:employee_role) { FactoryGirl.create(:employee_role, census_employee_id: new_census_employee.id, person: person, employer_profile: new_census_employee.employer_profile)}
      
      it "should not build a new employee role record if it exists one", dbclean: :after_each do
        new_census_employee.update_attribute(:employee_role_id, employee_role.id)
        id = new_census_employee.employee_role.id
        expect(new_census_employee.employee_role.id).to eq id
        subject.migrate
        new_census_employee.reload
        expect(new_census_employee.employee_role.id).to eq id
      end
    end
  end
end
