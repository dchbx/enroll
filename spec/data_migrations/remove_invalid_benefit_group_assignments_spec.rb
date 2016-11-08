require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "remove_invalid_benefit_group_assignments")

describe RemoveInvalidBenefitGroupAssignments do

  let(:given_task_name) { "remove_invalid_benefit_group_assignments" }
  subject { RemoveInvalidBenefitGroupAssignments.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe "changing plan year's state" do

    let!(:benefit_group_one)     { FactoryGirl.create(:benefit_group, plan_year: plan_year, title: "first_one")}
    let!(:benefit_group_two)     { FactoryGirl.create(:benefit_group, plan_year: plan_year, title: "second_one")}
    let!(:plan_year)         { FactoryGirl.create(:plan_year, aasm_state: "draft", employer_profile: employer_profile) }
    let(:employer_profile)  { FactoryGirl.create(:employer_profile) }
    let(:census_employee) { FactoryGirl.create(:census_employee, employer_profile_id: employer_profile.id)}

    before(:each) do
      allow(ENV).to receive(:[]).with("fein").and_return(employer_profile.parent.fein)
      census_employee.benefit_group_assignments << BenefitGroupAssignment.new(benefit_group: benefit_group_two, start_on: benefit_group_one.start_on, is_active: true)
      census_employee.save
    end

    context "removing the benefit group assignments" do

      it "should remove the invalid benefit group assignments and add a default one" do
        expect(census_employee.benefit_group_assignments.size).to eq 2
        expect(census_employee.benefit_group_assignments.where(benefit_group_id: benefit_group_two.id).count).to eq 1
        subject.migrate
        census_employee.reload
        expect(census_employee.benefit_group_assignments.where(benefit_group_id: benefit_group_two.id).count).to eq 0
        expect(census_employee.benefit_group_assignments.size).to eq 1
      end

      it "should create a default benefit group assignment with first benefit group" do
        subject.migrate
        census_employee.reload
        expect(census_employee.benefit_group_assignments.first.benefit_group.id).to eq benefit_group_one.id
      end
    end
  end
end
