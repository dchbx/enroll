require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "remove_benefit_package")

describe RemoveBenefitPackage, dbclean: :after_each do

  let(:given_task_name) { "remove_benefit_package" }
  subject { RemoveBenefitPackage.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe "remove benefit package", dbclean: :after_each do

    let(:family) { FactoryBot.create(:family, :with_primary_family_member)}
    let!(:hbx_enrollment) { FactoryBot.create(:hbx_enrollment, family: family, household: family.active_household, benefit_group_assignment_id: benefit_group_assignment.id, benefit_group_id: benefit_group.id)}
    let(:census_employee) { FactoryBot.create(:census_employee)}
    let!(:benefit_group_assignment)  { FactoryBot.create(:benefit_group_assignment, benefit_group: benefit_group, census_employee: census_employee) }
    let(:benefit_group) { FactoryBot.create(:benefit_group, plan_year: plan_year, title: "this is our title") }
    let(:benefit_group_two) { FactoryBot.create(:benefit_group, plan_year: plan_year) }
    let(:plan_year)         { FactoryBot.create(:plan_year, employer_profile: employer_profile) }
    let(:employer_profile)  { FactoryBot.create(:employer_profile) }

    
    it "should remove the benefit package" do
      ClimateControl.modify fein:employer_profile.parent.fein, aasm_state: plan_year.aasm_state, id: benefit_group.id, existing_bg_id: benefit_group_two.id, new_name_for_bg: "new_title" do 
        expect(plan_year.benefit_groups.size).to eq 2
        subject.migrate
        plan_year.reload
        expect(plan_year.benefit_groups.size).to eq 1
      end
    end

    it "should remove the benefit group assignments and enrollments" do
      ClimateControl.modify fein:employer_profile.parent.fein, aasm_state: plan_year.aasm_state, id: benefit_group.id, existing_bg_id: benefit_group_two.id, new_name_for_bg: "new_title" do 
        expect(benefit_group.benefit_group_assignments.first.hbx_enrollments.size).to eq 1
        expect(benefit_group.benefit_group_assignments.size).to eq 1
        subject.migrate
        plan_year.reload
        expect(benefit_group.benefit_group_assignments.size).to eq 0
      end
    end

    it "should change the benefit group title" do
      ClimateControl.modify fein:employer_profile.parent.fein, aasm_state: plan_year.aasm_state, id: benefit_group.id, existing_bg_id: benefit_group_two.id, new_name_for_bg: "new_title" do 
        subject.migrate
        plan_year.reload
        expect(plan_year.benefit_groups.first.title).to eq "New title"
      end
    end
  end
end
