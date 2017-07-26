require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "link_employees_to_employer")

describe LinkEmployeesToEmployer, dbclean: :after_each do

  let(:given_task_name) { "link_employees_to_employer" }
  subject { LinkEmployeesToEmployer.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end
  
  describe "census employee's not linked" do    
    let(:plan_year) { FactoryGirl.create(:plan_year) }
    let!(:benefit_group) { FactoryGirl.create(:benefit_group, plan_year: plan_year)}
    let(:family) { FactoryGirl.create(:family, :with_primary_family_member) }
    let(:hbx_enrollment) { FactoryGirl.create(:hbx_enrollment,household: family.active_household)}
    let(:benefit_group_assignment) {FactoryGirl.build(:benefit_group_assignment, benefit_group: benefit_group, hbx_enrollment: hbx_enrollment, start_on: TimeKeeper.date_of_record - 5.years)}
    let(:census_employee) { FactoryGirl.create(:census_employee, employer_profile_id: plan_year.employer_profile.id)}
    let(:census_employee2) { FactoryGirl.create(:census_employee, employer_profile_id: plan_year.employer_profile.id)}
    let(:census_employee3) { FactoryGirl.create(:census_employee, employer_profile_id: plan_year.employer_profile.id)}
    let(:census_employee4) { FactoryGirl.create(:census_employee, employer_profile_id: plan_year.employer_profile.id)}
    let(:census_employee5) { FactoryGirl.create(:census_employee, employer_profile_id: plan_year.employer_profile.id)}
    
    before(:each) do
      allow(ENV).to receive(:[]).with("ce1").and_return census_employee
      allow(ENV).to receive(:[]).with("ce2").and_return census_employee2
      allow(ENV).to receive(:[]).with("ce3").and_return census_employee3
      allow(ENV).to receive(:[]).with("ce4").and_return census_employee4
      allow(ENV).to receive(:[]).with("ce5").and_return census_employee5
    end
    it "employees should have eligible state then employee role linked states" do
      plan_year.update(aasm_state:'published')
      expect(census_employee.aasm_state).to eq "eligible"
      expect(census_employee2.aasm_state).to eq "eligible"
      expect(census_employee3.aasm_state).to eq "eligible"
      expect(census_employee4.aasm_state).to eq "eligible"
      expect(census_employee5.aasm_state).to eq "eligible"
      subject.migrate
      census_employee.reload
      census_employee2.reload
      census_employee3.reload
      census_employee4.reload
      census_employee5.reload
      expect(census_employee.aasm_state).to eq "employee_role_linked"
      expect(census_employee2.aasm_state).to eq "employee_role_linked"
      expect(census_employee3.aasm_state).to eq "employee_role_linked"
      expect(census_employee4.aasm_state).to eq "employee_role_linked"
      expect(census_employee5.aasm_state).to eq "employee_role_linked"
    end
  end 
end