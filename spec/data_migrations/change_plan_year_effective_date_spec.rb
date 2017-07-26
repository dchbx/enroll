require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "change_plan_year_effective_date")

describe ChangePlanYearEffectiveDate, dbclean: :after_each do

  let(:given_task_name) { "change_plan_year_effective_date" }
  subject { ChangePlanYearEffectiveDate.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe "changing plan year's effective date & reference plan and force publishing the plan year", dbclean: :after_each do

    let(:plan_year) { FactoryGirl.create(:future_plan_year, aasm_state: "draft") }
    let(:benefit_group) { FactoryGirl.create(:benefit_group, plan_year: plan_year)}
    let(:plan) { FactoryGirl.create(:plan, :with_premium_tables) }
    let(:family) { FactoryGirl.create(:family, :with_primary_family_member)}
    let(:enrollment) { FactoryGirl.create(:hbx_enrollment, household: family.active_household)}
    let(:census_employee) { FactoryGirl.create(:census_employee, employer_profile_id: plan_year.employer_profile.id, :aasm_state => "eligible") }

    before(:each) do
      allow(ENV).to receive(:[]).with("fein").and_return(plan_year.employer_profile.parent.fein)
      allow(ENV).to receive(:[]).with("aasm_state").and_return(plan_year.aasm_state)
      allow(ENV).to receive(:[]).with("py_new_start_on").and_return(plan_year.start_on - 1.month)
      allow(ENV).to receive(:[]).with("referenece_plan_hios_id").and_return(plan.hios_id)
      allow(ENV).to receive(:[]).with("ref_plan_active_year").and_return(plan.active_year)
      allow(ENV).to receive(:[]).with("action_on_enrollments").and_return("")
      allow(ENV).to receive(:[]).with("plan_year_state").and_return("")
      allow(benefit_group).to receive(:elected_plans_by_option_kind).and_return [plan]
      plan_year.employer_profile.update_attributes(profile_source: "conversion")
    end

    it "should change the plan year effective on date" do
      start_on = plan_year.start_on
      expect(start_on).to eq (TimeKeeper.date_of_record + 2.months).beginning_of_month
      subject.migrate
      plan_year.reload
      expect(plan_year.start_on).to eq start_on - 1.month
    end

    it "should change the reference plan" do
      subject.migrate
      plan_year.reload
      expect(plan_year.benefit_groups.first.reference_plan.hios_id).to eq plan.hios_id
    end

    it "should not publish the plan year" do
      subject.migrate
      plan_year.reload
      expect(plan_year.aasm_state).to eq "draft"
    end

    it "should publish the plan year" do
      allow(ENV).to receive(:[]).with("REDIS_URL").and_return("redis://what") # No
      allow(ENV).to receive(:[]).with("REDIS_NAMESPACE_QUIET").and_return("what") # Idea
      allow(ENV).to receive(:[]).with("REDIS_NAMESPACE_DEPRECATIONS").and_return("what") # WTF
      allow(ENV).to receive(:[]).with("plan_year_state").and_return("force_publish")
      employer = plan_year.employer_profile
      employer.census_employees << census_employee
      employer.save!
      subject.migrate
      plan_year.reload
      expect(plan_year.aasm_state).not_to eq "draft"
    end

    it "should revert the renewal py if received args as revert renewal" do
      allow(ENV).to receive(:[]).with("plan_year_state").and_return("revert_renewal")
      plan_year.update_attributes(aasm_state: "renewing_enrolling")
      enrollment.update_attributes(benefit_group_id: plan_year.benefit_groups.first.id, aasm_state: "auto_renewing")
      allow(ENV).to receive(:[]).with("aasm_state").and_return(plan_year.aasm_state)
      subject.migrate
      enrollment.reload
      expect(enrollment.aasm_state).to eq "coverage_canceled"
    end

    it "should cancel the enrollments under renewal plan year if received args as revert renewal" do
      allow(ENV).to receive(:[]).with("plan_year_state").and_return("revert_renewal")
      plan_year.update_attributes(aasm_state: "renewing_enrolling")
      allow(ENV).to receive(:[]).with("aasm_state").and_return(plan_year.aasm_state)
      subject.migrate
      plan_year.reload
      expect(plan_year.aasm_state).to eq "renewing_draft"
    end

    it "should cancel the enrollments under inital py if received args as revert application" do
      allow(ENV).to receive(:[]).with("plan_year_state").and_return("revert_application")
      plan_year.update_attributes(aasm_state: "active")
      enrollment.update_attributes(benefit_group_id: plan_year.benefit_groups.first.id, aasm_state: "coverage_enrolled")
      allow(ENV).to receive(:[]).with("aasm_state").and_return(plan_year.aasm_state)
      subject.migrate
      enrollment.reload
      expect(enrollment.aasm_state).to eq "coverage_canceled"
    end

    it "should revert the inital py if received args as revert application" do
      allow(ENV).to receive(:[]).with("plan_year_state").and_return("revert_application")
      plan_year.update_attributes(aasm_state: "active")
      allow(ENV).to receive(:[]).with("aasm_state").and_return(plan_year.aasm_state)
      subject.migrate
      plan_year.reload
      expect(plan_year.aasm_state).to eq "draft"
    end

    it "should set the enrollment effective on date as py start on date if enrollment has an effective date prior to py" do
      enrollment.update_attributes(benefit_group_id: benefit_group.id, effective_on: plan_year.start_on - 3.months)
      subject.migrate
      enrollment.reload
      plan_year.reload
      expect(enrollment.effective_on).to eq plan_year.start_on
    end

    it "should not change the enrollment effective on date if enrollment has an effective date after to py start date" do
      enrollment.update_attributes(benefit_group_id: benefit_group.id, effective_on: TimeKeeper.date_of_record + 3.months)
      subject.migrate
      enrollment.reload
      expect(enrollment.effective_on).to eq TimeKeeper.date_of_record + 3.months
    end

    it "should set the enrollment effective on date as py start on date if it receives env variable as py_start_on" do
      enrollment.update_attributes(benefit_group_id: benefit_group.id, effective_on: TimeKeeper.date_of_record + 3.months)
      allow(ENV).to receive(:[]).with("action_on_enrollments").and_return("py_start_on")
      subject.migrate
      enrollment.reload
      plan_year.reload
      expect(enrollment.effective_on).to eq plan_year.start_on
    end

    it "should output an error if plan year does not belong to conversion employer" do
      plan_year.employer_profile.update_attributes(profile_source: "self_serve")
      expect(subject.migrate).to eq nil
    end

    it "should output an error if plan year has published renewing plan year" do
      plan_year.update_attributes(aasm_state: "renewing_enrolling")
      allow(ENV).to receive(:[]).with("aasm_state").and_return(plan_year.aasm_state)
      expect(subject.migrate).to eq nil
    end
  end
end
