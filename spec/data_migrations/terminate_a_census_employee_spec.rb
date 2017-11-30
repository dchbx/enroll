require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "terminate_a_census_employee")
describe TerminateACensusEmployee, dbclean: :after_each do
  let(:given_task_name) { "terminate a census_employee" }
  subject { TerminateACensusEmployee.new(given_task_name, double(:current_scope => nil)) }

  describe "changes the census employees aasm_state to terminated" do
    let(:benefit_group)            { FactoryGirl.build(:benefit_group) }
    let(:plan_year)                { FactoryGirl.build(:plan_year, benefit_groups: [benefit_group], start_on: Date.new(Date.today.year,Date.today.month,1)) }
    let(:employer_profile)         { FactoryGirl.create(:employer_profile, plan_years: [plan_year]) }
    let(:benefit_group_assignment) { FactoryGirl.build(:benefit_group_assignment, benefit_group: benefit_group) }
    let(:census_employee) { FactoryGirl.create(:census_employee, employer_profile: employer_profile, benefit_group_assignments: [benefit_group_assignment] ) }
    
    before(:each) do
      allow(ENV).to receive(:[]).with("id").and_return(census_employee.id)
      allow(ENV).to receive(:[]).with("termination_date").and_return (TimeKeeper.date_of_record - 30.days)
      census_employee.update_attributes({:aasm_state => 'employee_role_linked'})
    end
    
    it "shoud have employee_role_linked" do
      expect(census_employee.aasm_state).to eq "employee_role_linked"
    end
    
    it "should have employment_terminated state" do
      subject.migrate
      census_employee.reload
      expect(census_employee.aasm_state).to eq "employment_terminated"
    end
  end
end