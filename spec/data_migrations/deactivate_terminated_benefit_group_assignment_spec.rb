require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "deactivate_terminated_benefit_group_assignment")

describe DeactivateTerminatedBenefitGroupAssignment, dbclean: :after_each do

  let(:given_task_name) { "deactivate_terminated_benefit_package" }
  subject { DeactivateTerminatedBenefitGroupAssignment.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe "deactivate terminated benefit group assignment" do

    let!(:benefit_group) { FactoryGirl.build(:benefit_group)}
    let(:plan_year) { FactoryGirl.create(:plan_year,benefit_groups:[benefit_group]) }
    let(:family) { FactoryGirl.create(:family, :with_primary_family_member) }
    let(:hbx_enrollment) { FactoryGirl.create(:hbx_enrollment,household: family.active_household,benefit_group:benefit_group)}
    let!(:invalid_benefit_group_assignment) {FactoryGirl.build(:benefit_group_assignment, is_active:true, aasm_state:'coverage_terminated',benefit_group_id: benefit_group.id,hbx_enrollment: hbx_enrollment, start_on: plan_year.start_on)}
    let!(:valid_benefit_group_assignment) {FactoryGirl.build(:benefit_group_assignment, is_active:true, aasm_state:'coverage_selected',benefit_group_id: benefit_group.id,hbx_enrollment: hbx_enrollment, start_on: plan_year.start_on)}
    let!(:census_employee) { FactoryGirl.create(:census_employee, employer_profile_id: plan_year.employer_profile.id,benefit_group_assignments:[invalid_benefit_group_assignment,valid_benefit_group_assignment])}

    context "updating benefit group assignments", dbclean: :after_each do

      it "should update the invalid benefit group assignments" do
        expect(invalid_benefit_group_assignment.is_active?).to be_truthy # before migration
        subject.migrate
        invalid_benefit_group_assignment.reload
        expect(invalid_benefit_group_assignment.is_active?).to be_falsey  # after migration
        expect(invalid_benefit_group_assignment.end_on).to eq plan_year.end_on
      end

      it "should not update valid benefit group assignments" do
        expect(valid_benefit_group_assignment.is_active?).to be_truthy # before migration
        subject.migrate
        valid_benefit_group_assignment.reload
        expect(valid_benefit_group_assignment.is_active?).to be_truthy  # after migration
        expect(valid_benefit_group_assignment.end_on).to eq nil
      end
    end
  end
end