require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "fix_benefit_group_assignments_for_conversion_er_without_active_plan_year")

describe FixBenefitGroupAssignmentsForConversionErWithoutActivePlanYear, dbclean: :after_each do
  let(:given_task_name) { "fix_benefit_group_assignments_for_conversion_er_without_active_plan_year" }
  subject { FixBenefitGroupAssignmentsForConversionErWithoutActivePlanYear.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe "changing organization's fein" do
    let(:organization) { FactoryGirl.create(:organization, :with_conversion_expired_and_renewing_canceled_plan_years) }
    let!(:census_employee) { FactoryGirl.create :census_employee, employer_profile_id: organization.employer_profile.id }

    it "should not have any active_benefit_group_assignment" do
      expect(census_employee.active_benefit_group_assignment).to eq nil
    end

    it "should assign a benefit group assignment" do
      subject.migrate
      census_employee.reload
      expect(census_employee.active_benefit_group_assignment).not_to eq nil
    end
  end
end
