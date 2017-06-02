require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "activate_benefit_group_assignment")

describe ActivateBenefitGroupAssignment do

  let(:given_task_name) { "activate_benefit_group_assignment" }
  subject { ActivateBenefitGroupAssignment.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe "activate benefit group assignment" do

    # let!(:benefit_group1)     { FactoryGirl.create(:benefit_group, plan_year: plan_year)}
    # let!(:benefit_group2)     { FactoryGirl.create(:benefit_group, plan_year: plan_year)}
    # let!(:plan_year)         { FactoryGirl.create(:plan_year, aasm_state: "draft", employer_profile: employer_profile) }
    # let(:employer_profile)  { FactoryGirl.create(:employer_profile) }
    let!(:census_employee) { FactoryGirl.create(:census_employee,ssn:"123456789")}

    let!(:benefit_group_assignment1)  { FactoryGirl.create(:benefit_group_assignment, is_active: false, census_employee: census_employee)}
    let!(:benefit_group_assignment2)  { FactoryGirl.create(:benefit_group_assignment, is_active: false, census_employee: census_employee)}
    before(:each) do
      allow(ENV).to receive(:[]).with("ce_ssn").and_return(census_employee.ssn)
      allow(ENV).to receive(:[]).with("bga_id").and_return(benefit_group_assignment1.id)
    end

    context "activate_benefit_group_assignment", dbclean: :after_each do
      it "should activate_related_benefit_group_assignment" do
        expect(benefit_group_assignment1.is_active).to eq false
        subject.migrate
        census_employee.reload
        expect(census_employee.benefit_group_assignments.where(id:benefit_group_assignment1.id).first.is_active).to eq true
      end
      it "should_not activate_unrelated_benefit_group_assignment" do
        expect(benefit_group_assignment2.is_active).to eq false
        subject.migrate
        census_employee.reload
        expect(census_employee.benefit_group_assignments.where(id:benefit_group_assignment2.id).first.is_active).to eq false
      end
    end
  end
end

