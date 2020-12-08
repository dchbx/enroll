require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "terminate_a_census_employee")

# Date.today converted to TimeKeeper

describe TerminateACensusEmployee, dbclean: :after_each do
  let(:given_task_name) { "terminate a census_employee" }
  subject { TerminateACensusEmployee.new(given_task_name, double(:current_scope => nil)) }

  describe "changes the census employees aasm_state to terminated" do
    let(:benefit_group)            { FactoryBot.build(:benefit_group) }
    let(:plan_year)                { FactoryBot.build(:plan_year, benefit_groups: [benefit_group], start_on: Date.new(TimeKeeper.date_of_record.year,TimeKeeper.date_of_record.month,1)) }
    let(:employer_profile)         { FactoryBot.create(:employer_profile, plan_years: [plan_year]) }
    let(:benefit_group_assignment) { FactoryBot.build(:benefit_group_assignment, benefit_group: benefit_group) }
    let(:census_employee) { FactoryBot.create(:census_employee, :old_case, employer_profile: employer_profile, benefit_group_assignments: [benefit_group_assignment] ) }

    around do |example|
     ClimateControl.modify id: census_employee.id,
                           termination_date: (TimeKeeper.date_of_record - 30.days).to_s do
       example.run
     end
    end

    before(:each) do
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
