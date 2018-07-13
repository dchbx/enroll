require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "change_initial_plan_year_aasm_state")


describe ChangeInitialPlanYearAasmState, dbclean: :after_each do

  let(:given_task_name) { "change_initial_plan_year_aasm_state" }
  subject { ChangeInitialPlanYearAasmState.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe "updating aasm_state of the initial plan year", dbclean: :after_each do
    let(:benefit_group) { FactoryGirl.create(:benefit_group) }
    let(:canceled_plan_year){ FactoryGirl.build(:plan_year,start_on:TimeKeeper.date_of_record.next_month.beginning_of_month,open_enrollment_end_on:TimeKeeper.date_of_record,aasm_state: "canceled",benefit_groups:[benefit_group]) }
    let(:employer_profile){ FactoryGirl.create(:employer_profile, aasm_state:'applicant',plan_years: [canceled_plan_year]) }
    let(:organization)  { employer_profile.organization }
    let(:benefit_group_assignment) { FactoryGirl.build(:benefit_group_assignment, benefit_group: benefit_group)}
    let(:census_employee) { FactoryGirl.create(:census_employee,employer_profile: employer_profile,:benefit_group_assignments => [benefit_group_assignment]) }

    before(:each) do
      allow(ENV).to receive(:[]).with("fein").and_return(organization.fein)
      allow(ENV).to receive(:[]).with("plan_year_start_on").and_return(canceled_plan_year.start_on)
      allow(ShopNoticesNotifierJob).to receive(:perform_later).and_return true
      allow(ENV).to receive(:[]).with("py_state").and_return('')
    end

    it "should update aasm_state of plan year" do
      expect(canceled_plan_year.aasm_state).to eq "canceled"  # before migration
      subject.migrate
      canceled_plan_year.reload
      expect(canceled_plan_year.aasm_state).to eq "enrolling"  # after migration
    end

    it "should not update active plan year" do
      canceled_plan_year.update_attributes(aasm_state:'active') # before migration
      subject.migrate
      canceled_plan_year.reload
      expect(canceled_plan_year.aasm_state).to eq "active" # after migration
    end

    it "should update plan year aasm state of plan year after force publish date" do
      canceled_plan_year.update_attributes(aasm_state:'application_ineligible') # before migration
      subject.migrate
      canceled_plan_year.reload
      canceled_plan_year.employer_profile.reload
      expect(canceled_plan_year.aasm_state).to eq "enrolling" # after migration
    end
  end

  describe "updating aasm_state for plan year", dbclean: :after_each do
    let(:benefit_group) { FactoryGirl.create(:benefit_group) }
    let(:plan_year){ FactoryGirl.build(:plan_year,start_on:TimeKeeper.date_of_record.next_month.beginning_of_month,benefit_groups:[benefit_group]) }
    let(:employer_profile){ FactoryGirl.build(:employer_profile, aasm_state:'binder_paid',plan_years: [plan_year]) }
    let(:organization)  {FactoryGirl.create(:organization,employer_profile:employer_profile)}
    let(:benefit_group_assignment) { FactoryGirl.build(:benefit_group_assignment, benefit_group: benefit_group)}
    let(:census_employee) { FactoryGirl.create(:census_employee,employer_profile: employer_profile,:benefit_group_assignments => [benefit_group_assignment]) }

    before(:each) do
      allow(ENV).to receive(:[]).with("fein").and_return(organization.fein)
      allow(ENV).to receive(:[]).with("plan_year_start_on").and_return(plan_year.start_on)
      allow(ENV).to receive(:[]).with("py_state").and_return('enrolled')
    end

    it "should update aasm_state of plan year" do
      allow_any_instance_of(PlanYear).to receive(:is_enrollment_valid?).and_return(false)
      expect(plan_year.valid?).to be_truthy
      subject.migrate
      plan_year.reload
      plan_year.employer_profile.reload
      expect(plan_year.aasm_state).to eq "enrolled"
    end
  end
end
