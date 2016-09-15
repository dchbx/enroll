require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "update_benefit_group")

describe UpdateBenefitGroup do
  let(:given_task_name) { "update_benefit_group" }
  subject { UpdateBenefitGroup.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe "updating active benefit group", :dbclean => :after_each do
    context "changing field in benefit group assignment", :dbclean => :after_each do
      before :each do
        DatabaseCleaner.clean
      end
      let(:employer_profile) { benefit_group.plan_year.employer_profile }
      let(:active_plan_year) { FactoryGirl.create(:plan_year, employer_profile: employer_profile, benefit_groups: [benefit_group_two], aasm_state: "active")}
      let(:renewal_plan_year) { FactoryGirl.create(:renewing_plan_year, employer_profile: employer_profile, benefit_groups: [benefit_group], aasm_state: "renewing_enrolling")}
      let(:census_employee) { FactoryGirl.create(:census_employee, employer_profile: employer_profile)}
      let(:benefit_group_two) { FactoryGirl.create(:benefit_group)}
      let(:benefit_group)     { FactoryGirl.create(:benefit_group)}
      let(:benefit_group_assignment) { FactoryGirl.create(:benefit_group_assignment, benefit_group: benefit_group, census_employee: census_employee)}

      it "should change the is_active state of the benefit group assignment" do
        active_plan_year.save
        renewal_plan_year.save
        expect(census_employee.active_benefit_group).to eq nil
        benefitgroup = active_plan_year.benefit_groups.first.benefit_group_assignments.detect { |assignment| assignment.is_active? }
        subject.migrate
        census_employee.reload
        expect(census_employee.active_benefit_group).to eq benefitgroup
      end
    end
  end
end
