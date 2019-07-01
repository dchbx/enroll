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

    let(:employer_profile)  { FactoryBot.create(:employer_profile)}
    let!(:plan_year) { FactoryBot.create(:future_plan_year, aasm_state: "draft", employer_profile: employer_profile, start_on: (TimeKeeper.date_of_record + 2.months).beginning_of_month) }
    let!(:benefit_group) { FactoryBot.create(:benefit_group, plan_year: plan_year)}
    let(:plan) { FactoryBot.create(:plan, :with_premium_tables) }
    let(:family) { FactoryBot.create(:family, :with_primary_family_member)}
    let(:enrollment) { FactoryBot.create(:hbx_enrollment, family: family, household: family.active_household)}
    let(:benefit_group_assignment) {FactoryBot.build(:benefit_group_assignment, benefit_group: benefit_group)}
    let(:census_employee) { FactoryBot.create(:census_employee, employer_profile_id: plan_year.employer_profile.id, :aasm_state => "eligible", benefit_group_assignments: [benefit_group_assignment]) }


    before(:each) do 
      plan_year.employer_profile.update_attributes(profile_source: "conversion")
    end
    it "should change the plan year effective on date" do
      ClimateControl.modify fein: plan_year.employer_profile.parent.fein,
        aasm_state: plan_year.aasm_state,
        py_new_start_on: "#{plan_year.start_on - 1.month}",
        referenece_plan_hios_id: plan.hios_id,
        ref_plan_active_year: "#{plan.active_year}",
        action_on_enrollments: "",
        plan_year_state: "" do
        allow(benefit_group).to receive(:elected_plans_by_option_kind).and_return [plan]
        start_on = plan_year.start_on
        expect(start_on).to eq (TimeKeeper.date_of_record + 2.months).beginning_of_month
        subject.migrate
        plan_year.reload
        expect(plan_year.start_on).to eq (start_on - 1.month)
      end
    end

    it "should change the reference plan" do
      ClimateControl.modify fein: plan_year.employer_profile.parent.fein,
      aasm_state: plan_year.aasm_state,
      py_new_start_on: "#{plan_year.start_on - 1.month}",
      referenece_plan_hios_id: plan.hios_id,
      ref_plan_active_year: "#{plan.active_year}",
      action_on_enrollments: "",
      plan_year_state: "" do
      employer_profile.update_attributes!(profile_source:'conversion')
      subject.migrate
      plan_year.reload
      expect(plan_year.benefit_groups.first.reference_plan.hios_id).to eq plan.hios_id
      end
    end

    it "should not publish the plan year" do
      ClimateControl.modify fein: plan_year.employer_profile.parent.fein,
        aasm_state: plan_year.aasm_state,
        py_new_start_on: "#{plan_year.start_on - 1.month}",
        referenece_plan_hios_id: plan.hios_id,
        ref_plan_active_year: "#{plan.active_year}",
        action_on_enrollments: "",
        plan_year_state: "" do
        employer_profile.update_attributes!(profile_source:'conversion')
        subject.migrate
        plan_year.reload
        expect(plan_year.aasm_state).to eq "draft"
      end
    end

    it "should publish the plan year" do
      ClimateControl.modify fein: plan_year.employer_profile.parent.fein,
              aasm_state: plan_year.aasm_state,
              py_new_start_on: "#{plan_year.start_on - 1.month}",
              referenece_plan_hios_id: plan.hios_id,
              ref_plan_active_year: "#{plan.active_year}",
              action_on_enrollments: "",
              REDIS_URL: "redis://what",
              REDIS_NAMESPACE_QUIET: "what",
              REDIS_NAMESPACE_DEPRECATIONS: "what", 
              plan_year_state: "force_publish" do
          allow_any_instance_of(CensusEmployee).to receive(:has_benefit_group_assignment?).and_return(true)
          allow(benefit_group).to receive(:elected_plans_by_option_kind).and_return [plan]
          plan_year.employer_profile.update_attributes(profile_source: "conversion")
          employer = plan_year.employer_profile
          employer.census_employees << census_employee
          employer.save!
          subject.migrate
          plan_year.reload
          expect(plan_year.aasm_state).not_to eq "draft"
        end
    end

    it "should revert the renewal py if received args as revert renewal" do
      plan_year.update_attributes!(aasm_state: "renewing_enrolling")
        ClimateControl.modify fein: plan_year.employer_profile.parent.fein,
          aasm_state: plan_year.aasm_state,
          py_new_start_on: "#{plan_year.start_on - 1.month}",
          referenece_plan_hios_id: plan.hios_id,
          ref_plan_active_year: "#{plan.active_year}",
          action_on_enrollments: "",
          REDIS_URL: "redis://what",
          REDIS_NAMESPACE_QUIET: "what",
          REDIS_NAMESPACE_DEPRECATIONS: "what", 
          plan_year_state: "revert_renewal" do
            plan_year.employer_profile.update_attributes!(profile_source: "conversion")
            enrollment.update_attributes(benefit_group_id: plan_year.benefit_groups.first.id, aasm_state: "auto_renewing")
            subject.migrate
            enrollment.reload
            plan_year.reload
            expect(enrollment.aasm_state).to eq "coverage_canceled"
            expect(plan_year.aasm_state).to eq "renewing_draft"
      end
    end
    

    it "should cancel the enrollments under inital py if received args as revert application" do
      plan_year.update_attributes(aasm_state: "active")
      enrollment.update_attributes(benefit_group_id: plan_year.benefit_groups.first.id, aasm_state: "coverage_enrolled")
      ClimateControl.modify fein: plan_year.employer_profile.parent.fein,
        aasm_state: plan_year.aasm_state,
        py_new_start_on: "#{plan_year.start_on - 1.month}",
        referenece_plan_hios_id: plan.hios_id,
        ref_plan_active_year: "#{plan.active_year}",
        action_on_enrollments: "",
        REDIS_URL: "redis://what",
        REDIS_NAMESPACE_QUIET: "what",
        REDIS_NAMESPACE_DEPRECATIONS: "what", 
        plan_year_state: "revert_application" do
        subject.migrate
        enrollment.reload
        plan_year.reload
        expect(enrollment.aasm_state).to eq "coverage_canceled"
        expect(plan_year.aasm_state).to eq "draft"
      end
    end
    
    
    it "should set the enrollment effective on date as py start on date if enrollment has an effective date prior to py" do
      enrollment.update_attributes(benefit_group_id: benefit_group.id, effective_on: plan_year.start_on - 3.months)
      ClimateControl.modify fein: plan_year.employer_profile.parent.fein,
      aasm_state: plan_year.aasm_state,
      py_new_start_on: "#{plan_year.start_on - 1.month}",
      referenece_plan_hios_id: plan.hios_id,
      ref_plan_active_year: "#{plan.active_year}",
      action_on_enrollments: "",
      REDIS_URL: "redis://what",
      REDIS_NAMESPACE_QUIET: "what",
      REDIS_NAMESPACE_DEPRECATIONS: "what", 
      plan_year_state: "revert_application" do
        subject.migrate
        enrollment.reload
        plan_year.reload
        expect(enrollment.effective_on).to eq plan_year.start_on
      end
    end

    it "should not change the enrollment effective on date if enrollment has an effective date after to py start date" do
      enrollment.update_attributes(benefit_group_id: benefit_group.id, effective_on: TimeKeeper.date_of_record + 3.months)
      ClimateControl.modify fein: plan_year.employer_profile.parent.fein,
        aasm_state: plan_year.aasm_state,
        py_new_start_on: "#{plan_year.start_on - 1.month}",
        referenece_plan_hios_id: plan.hios_id,
        ref_plan_active_year: "#{plan.active_year}",
        action_on_enrollments: "",
        REDIS_URL: "redis://what",
        REDIS_NAMESPACE_QUIET: "what",
        REDIS_NAMESPACE_DEPRECATIONS: "what", 
        plan_year_state: "revert_application" do
        subject.migrate
        enrollment.reload
        expect(enrollment.effective_on).to eq TimeKeeper.date_of_record + 3.months
      end
    end

    it "should set the enrollment effective on date as py start on date if it receives env variable as py_start_on" do
      enrollment.update_attributes(benefit_group_id: benefit_group.id, effective_on: TimeKeeper.date_of_record + 3.months)
      ClimateControl.modify fein: plan_year.employer_profile.parent.fein,
        aasm_state: plan_year.aasm_state,
        py_new_start_on: "#{plan_year.start_on - 1.month}",
        referenece_plan_hios_id: plan.hios_id,
        ref_plan_active_year: "#{plan.active_year}",
        action_on_enrollments: "py_start_on",
        REDIS_URL: "redis://what",
        REDIS_NAMESPACE_QUIET: "what",
        REDIS_NAMESPACE_DEPRECATIONS: "what", 
        plan_year_state: "revert_application" do
        subject.migrate
        enrollment.reload
        plan_year.reload
      expect(enrollment.effective_on).to eq plan_year.start_on
      end
    end

    it "should output an error if plan year does not belong to conversion employer" do
      plan_year.employer_profile.update_attributes(profile_source: "self_serve")
      ClimateControl.modify fein: plan_year.employer_profile.parent.fein,
        aasm_state: plan_year.aasm_state,
        py_new_start_on: "#{plan_year.start_on - 1.month}",
        referenece_plan_hios_id: plan.hios_id,
        ref_plan_active_year: "#{plan.active_year}",
        action_on_enrollments: "py_start_on",
        REDIS_URL: "redis://what",
        REDIS_NAMESPACE_QUIET: "what",
        REDIS_NAMESPACE_DEPRECATIONS: "what", 
        plan_year_state: "revert_application" do
      end
      expect(subject.migrate).to eq nil
    end

    it "should output an error if plan year has published renewing plan year" do
      plan_year.update_attributes(aasm_state: "renewing_enrolling")
      ClimateControl.modify fein: plan_year.employer_profile.parent.fein,
        aasm_state: plan_year.aasm_state,
        py_new_start_on: "#{plan_year.start_on - 1.month}",
        referenece_plan_hios_id: plan.hios_id,
        ref_plan_active_year: "#{plan.active_year}",
        action_on_enrollments: "py_start_on",
        REDIS_URL: "redis://what",
        REDIS_NAMESPACE_QUIET: "what",
        REDIS_NAMESPACE_DEPRECATIONS: "what", 
        plan_year_state: "revert_application" do
      expect(subject.migrate).to eq nil
      end
    end
  end
end
