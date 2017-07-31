require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "update_invalid_benefit_group_assignment_for_census_employee")

describe UpdateInvalidBenefitGroupAssignmentForCensusEmployee do

  let(:given_task_name) { "update_invalid_benefit_group_assignment_for_census_employee" }
  subject { UpdateInvalidBenefitGroupAssignmentForCensusEmployee.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe "updating benefit group assignment" do

    let(:family) { FactoryGirl.create(:family, :with_primary_family_member)}
    let!(:hbx_enrollment1) { FactoryGirl.create(:hbx_enrollment, household: family.active_household, benefit_group_assignment_id: benefit_group_assignment1.id, benefit_group_id: benefit_group.id)}
    let(:census_employee) { FactoryGirl.create(:census_employee)}
    let!(:benefit_group_assignment1)  { FactoryGirl.create(:benefit_group_assignment, census_employee: census_employee) }
    let(:benefit_group) { FactoryGirl.create(:benefit_group, plan_year: plan_year, title: "this is our title") }
    let(:plan_year)         { FactoryGirl.create(:plan_year, employer_profile: employer_profile) }
    let(:employer_profile)  { FactoryGirl.create(:employer_profile) }

    before(:each) do
      allow(ENV).to receive(:[]).with("census_employee_id").and_return(census_employee.id)
      benefit_group_assignment1.hbx_enrollment_id = hbx_enrollment1.id
      benefit_group_assignment1.save
    end

   
    it "should update benefit group assignment for census employee" do
      subject.migrate
      benefit_group_assignment1.reload
      expect(benefit_group_assignment1.hbx_enrollment_id).to be_nil
      expect(benefit_group_assignment1.is_active).to be_falsey
      expect(benefit_group_assignment1.aasm_state).to eq('coverage_expired')
    end
  end
end
