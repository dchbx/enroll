require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "remove_benefit_package")

describe RemoveBenefitPackage do

  let(:given_task_name) { "remove_benefit_package" }
  subject { RemoveBenefitPackage.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe "remove benefit package", dbclean: :after_each do

    let(:family) { FactoryGirl.create(:family, :with_primary_family_member)}
    let!(:hbx_enrollment) { FactoryGirl.create(:hbx_enrollment, household: family.active_household, benefit_group_assignment_id: benefit_group_assignment.id, benefit_group_id: benefit_group.id)}
    let(:census_employee) { FactoryGirl.create(:census_employee)}
    let!(:benefit_group_assignment)  { FactoryGirl.create(:benefit_group_assignment, benefit_group: benefit_group, census_employee: census_employee) }
    let(:benefit_group) { FactoryGirl.create(:benefit_group, plan_year: plan_year, title: "this is our title") }
    let(:benefit_group_two) { FactoryGirl.create(:benefit_group, plan_year: plan_year) }
    let(:plan_year)         { FactoryGirl.create(:plan_year, employer_profile: employer_profile) }
    let(:employer_profile)  { FactoryGirl.create(:employer_profile) }

    before(:each) do
      allow(ENV).to receive(:[]).with("fein").and_return(employer_profile.parent.fein)
      allow(ENV).to receive(:[]).with("aasm_state").and_return(plan_year.aasm_state)
      allow(ENV).to receive(:[]).with("id").and_return(benefit_group.id)
      allow(ENV).to receive(:[]).with("existing_bg_id").and_return(benefit_group_two.id)
      allow(ENV).to receive(:[]).with("new_name_for_bg").and_return("new_title")
    end
    
    it "should remove the benefit package" do
      expect(plan_year.benefit_groups.size).to eq 2
      subject.migrate
      plan_year.reload
      expect(plan_year.benefit_groups.size).to eq 1
    end

    it "should remove the benefit group assignments and enrollments" do
      expect(benefit_group.benefit_group_assignments.first.hbx_enrollments.size).to eq 1
      expect(benefit_group.benefit_group_assignments.size).to eq 1
      subject.migrate
      plan_year.reload
      expect(benefit_group.benefit_group_assignments.size).to eq 0
    end

    it "should change the benefit group title" do
      subject.migrate
      plan_year.reload
      expect(plan_year.benefit_groups.first.title).to eq "New title"
    end
  end
end
