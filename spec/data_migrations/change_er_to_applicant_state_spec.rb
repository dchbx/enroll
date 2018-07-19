require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "change_er_to_applicant_state")

describe ChangeErToApplicantState do

  let(:given_task_name) { "change_er_to_applicant_state" }
  subject { ChangeErToApplicantState.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe "change employer profile to applicant state", dbclean: :after_each do
    let(:benefit_group) { FactoryGirl.create(:benefit_group)}
    let(:plan_year) { FactoryGirl.create(:plan_year, benefit_groups: [benefit_group], aasm_state: "canceled")}
    let(:employer_profile)     { FactoryGirl.build(:employer_profile, plan_years: [plan_year]) }
    let(:organization) { FactoryGirl.create(:organization, employer_profile:employer_profile)}
    let(:family) { FactoryGirl.build(:family, :with_primary_family_member)}
    let(:census_employee)   { FactoryGirl.create(:census_employee, employer_profile: employer_profile) }
    let(:employee_role)   { FactoryGirl.build(:employee_role, employer_profile: employer_profile )}
    let(:family) { FactoryGirl.create(:family, :with_primary_family_member)}
    let!(:enrollment) { FactoryGirl.create(:hbx_enrollment, household: family.active_household, aasm_state: "coverage_enrolled", benefit_group_id: plan_year.benefit_groups.first.id)}

    before(:each) do
      allow(ENV).to receive(:[]).with('plan_year_state').and_return(plan_year.aasm_state)
      allow(ENV).to receive(:[]).with('feins').and_return(plan_year.employer_profile.parent.fein)
      subject.migrate
      plan_year.reload
      enrollment.reload
    end

    it "should cancel the plan year" do
      expect(plan_year.aasm_state).to eq "canceled"
    end

    it "should change employer profile to applicant state" do
      expect(employer_profile.aasm_state).to eq "applicant"
    end
  end
end
