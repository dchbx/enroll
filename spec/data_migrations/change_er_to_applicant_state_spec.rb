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

  describe "change employer profile to applicant state", dbclean: :around_each do
    let(:benefit_group) { FactoryBot.create(:benefit_group)}
    let(:plan_year) { FactoryBot.create(:plan_year, benefit_groups: [benefit_group], aasm_state: "canceled")}
    let(:employer_profile)     { FactoryBot.build(:employer_profile, plan_years: [plan_year]) }
    let(:organization) { FactoryBot.create(:organization, employer_profile:employer_profile)}
    let(:family) { FactoryBot.build(:family, :with_primary_family_member)}
    let(:census_employee)   { FactoryBot.create(:census_employee, employer_profile: employer_profile) }
    let(:employee_role)   { FactoryBot.build(:employee_role, employer_profile: employer_profile )}
    let(:family) { FactoryBot.create(:family, :with_primary_family_member)}
    let!(:enrollment) { FactoryBot.create(:hbx_enrollment, family: family, household: family.active_household, aasm_state: "coverage_enrolled", benefit_group_id: plan_year.benefit_groups.first.id)}

    before(:each) do
      ClimateControl.modify plan_year_state: plan_year.aasm_state, feins: plan_year.employer_profile.parent.fein do
        subject.migrate
        plan_year.reload
        enrollment.reload
      end
    end

    it "should cancel the plan year" do
      expect(plan_year.aasm_state).to eq "canceled"
    end

    it "should change employer profile to applicant state" do
      expect(employer_profile.aasm_state).to eq "applicant"
    end
  end
end
