require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "remove_invalid_benefit_group_assignment_for_census_employee")

describe RemoveInvalidBenefitGroupAssignmentForCensusEmployee do

  let(:given_task_name) { "remove_invalid_benefit_group_assignment_for_census_employee" }
  subject { RemoveInvalidBenefitGroupAssignmentForCensusEmployee.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe "removing invalid benefit group assignment" do

    let!(:benefit_group)     { FactoryGirl.create(:benefit_group, plan_year: plan_year, title: "first_one")}
    let!(:employee_role) { FactoryGirl.create(:employee_role)}
    let!(:plan_year)         { FactoryGirl.create(:plan_year, employer_profile: employee_role.employer_profile) }
    let(:census_employee) { FactoryGirl.create(:census_employee, employer_profile_id: employee_role.employer_profile.id)}

    before(:each) do
      allow(ENV).to receive(:[]).with("employee_role_id").and_return(employee_role.id.to_s)
      employee_role.update_attribute(:census_employee_id, census_employee.id)
    end

    it "should not remove the benefit group assignment if there was beneift group associated with it" do
      expect(census_employee.benefit_group_assignments.size).to eq 1
      subject.migrate
      census_employee.reload
      expect(census_employee.benefit_group_assignments.size).to eq 1
    end

    it "should remove the benefit group assignment if there was no beneift group associated with it" do
      employee_role.census_employee.benefit_group_assignments.first.update_attribute(:benefit_group_id, nil)
      expect(census_employee.benefit_group_assignments.size).to eq 1
      subject.migrate
      census_employee.reload
      expect(census_employee.benefit_group_assignments.size).to eq 0
    end
  end
end
