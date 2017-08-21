require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "change_aasm_state_dot_census_employee")
describe ChangeAasmStateDotCensusEmployee, dbclean: :after_each do
  describe "given a task name" do
    let(:given_task_name) { "change_aasm_state_dot_census_employee" }
    subject {ChangeAasmStateDotCensusEmployee.new(given_task_name, double(:current_scope => nil)) }
      it "has the given task name" do
        expect(subject.name).to eql given_task_name
      end
    end
  describe "census employee not in terminated state" do
    subject {ChangeAasmStateDotCensusEmployee.new("change_aasm_state_dot_census_employee", double(:current_scope => nil)) }
       let(:benefit_group){ FactoryGirl.create(:benefit_group) }
      let(:plan_year){ FactoryGirl.create(:plan_year,benefit_groups:[benefit_group]) }
      let(:employer_profile_id){ plan_year.employer_profile.id }
      let(:census_employee){ FactoryGirl.create(:census_employee,employer_profile_id:employer_profile_id)}

      before :each do
        allow(ENV).to receive(:[]).with('census_employee_id').and_return census_employee.id
        census_employee.update_attributes!(aasm_state:'employment_terminated',employment_terminated_on:TimeKeeper.date_of_record,coverage_terminated_on:TimeKeeper.date_of_record)
      end
      it "should change dot of ce not in employment termination state" do
        subject.migrate
        census_employee.reload
        expect(census_employee.employment_terminated_on).to eq nil
        expect(census_employee.coverage_terminated_on).to eq nil
        expect(census_employee.aasm_state).to eq "employee_role_linked"

      end
    end
    
end
