require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "correct_invalid_benefit_group_assignments_for_employer")

describe CorrectInvalidBenefitGroupAssignmentsForEmployer do

  let(:given_task_name) { "correct_invalid_benefit_group_assignments_for_employer" }
  subject { CorrectInvalidBenefitGroupAssignmentsForEmployer.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe "changing plan year's state" do

    let!(:benefit_group_one)     { FactoryGirl.create(:benefit_group, plan_year: plan_year)}
    let!(:plan_year)         { FactoryGirl.create(:plan_year, aasm_state: "draft", employer_profile: employer_profile) }
    let(:employer_profile)  { FactoryGirl.create(:employer_profile) }
    let(:census_employee) { FactoryGirl.create(:census_employee, employer_profile_id: employer_profile.id)}

    before(:each) do
      allow(ENV).to receive(:[]).with("fein").and_return(employer_profile.parent.fein)
    end

    context "checking benefit group assignments", dbclean: :after_each do

      it "should remove the invalid benefit group assignments" do
        expect(census_employee.benefit_group_assignments.size).to eq 1
        census_employee.benefit_group_assignments.first.benefit_group.delete
        subject.migrate
        census_employee.reload
        expect(census_employee.benefit_group_assignments.size).to eq 0
      end

      it "should not remove the valid benefit group assignment" do
        subject.migrate
        census_employee.reload
        expect(census_employee.benefit_group_assignments.size).to eq 1
      end

      it "should change the incorrect start on date for invalid benefit group assignment" do
        census_employee.benefit_group_assignments.first.update_attribute(:start_on, plan_year.start_on - 2.months)
        subject.migrate
        census_employee.reload
        expect(census_employee.benefit_group_assignments.first.start_on).to eq [benefit_group_one.start_on, census_employee.hired_on].compact.max
      end

      it "should change the incorrect end on date for invalid benefit group assignment" do
        census_employee.benefit_group_assignments.first.update_attribute(:end_on, plan_year.end_on + 2.months)
        subject.migrate
        census_employee.reload
        expect(census_employee.benefit_group_assignments.first.end_on).to eq plan_year.end_on
      end
    end
  end
end
