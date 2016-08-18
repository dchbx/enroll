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
      let(:organization) { FactoryGirl.create(:organization, employer_profile: employer_profile, fein: "123456789")}
      let(:employer_profile) { FactoryGirl.create(:employer_profile)}
      let(:active_plan_year) { FactoryGirl.create(:plan_year, employer_profile: employer_profile, aasm_state: "active")}
      let(:renewal_plan_year) { FactoryGirl.create(:renewing_plan_year, employer_profile: employer_profile, benefit_groups: [benefit_group], aasm_state: "renewing_enrolling")}
      let(:census_employee) { FactoryGirl.create(:census_employee, employer_profile: employer_profile )}
      let(:benefit_group)     { FactoryGirl.create(:benefit_group)}
      let(:benefit_group_assignment) { FactoryGirl.create(:benefit_group_assignment, benefit_group: benefit_group, census_employee: census_employee)}

      before do
        allow(organization).to receive(:employer_profile).and_return employer_profile
        allow(employer_profile).to receive(:plan_years).and_return [active_plan_year]
        allow(employer_profile).to receive(:census_employees).and_return census_employee
        allow(benefit_group_assignment).to receive(:plan_year).and_return renewal_plan_year
        allow(census_employee).to receive(:renewal_benefit_group_assignment).and_return benefit_group_assignment
        allow(benefit_group).to receive(:plan_year).and_return renewal_plan_year
      end

      it "should change the is_active state of the benefit group assignment" do
        benefit_group_assignment.is_active = false
        benefit_group_assignment.save
        subject.migrate
        benefit_group_assignment.reload
        expect(benefit_group_assignment.is_active).to eq true
      end
    end
  end
end