require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "reinstate_plan_year")

describe ReinstatePlanYear, dbclean: :after_each do

  let(:given_task_name) { "reinstate_plan_year" }
  subject { ReinstatePlanYear.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe "reinstate_plan_year", dbclean: :after_each do

    let!(:employer_profile)  { FactoryGirl.build(:employer_profile) }
    let!(:organization)  { FactoryGirl.create(:organization,employer_profile:employer_profile)}
    let(:family) { FactoryGirl.create(:family, :with_primary_family_member)}
    let!(:census_employee) { FactoryGirl.create(:census_employee,employer_profile: employer_profile)}

    before(:each) do
      allow(ENV).to receive(:[]).with("fein").and_return(employer_profile.parent.fein)
      allow(ENV).to receive(:[]).with("plan_year_start_on").and_return(plan_year.start_on)
      allow(ENV).to receive(:[]).with("update_current_enrollment").and_return(true)
      allow(ENV).to receive(:[]).with("update_renewal_enrollment").and_return(true)
      allow(ENV).to receive(:[]).with("renewing_force_publish").and_return(true)
    end

    context "when reinstating active plan year plan year" do

      let(:benefit_group) { FactoryGirl.build(:benefit_group)}
      let(:plan_year) { FactoryGirl.build(:plan_year, aasm_state:'terminated', end_on: TimeKeeper.date_of_record + 30.days, terminated_on: TimeKeeper.date_of_record - 30.days,benefit_groups:[benefit_group]) }
      let!(:emp_plan_years) {employer_profile.plan_years << plan_year}
      let!(:enrollment_terminated) { FactoryGirl.create(:hbx_enrollment, :terminated, terminated_on: plan_year.end_on, benefit_group_id:benefit_group.id, household: family.active_household, terminate_reason: "")}
      let!(:ce_benefit_group_assignment) { FactoryGirl.build(:benefit_group_assignment,hbx_enrollment_id:enrollment_terminated.id, benefit_group_id:benefit_group.id, end_on:plan_year.end_on) }
      let!(:ce_assignments) { census_employee.benefit_group_assignments << ce_benefit_group_assignment}

      it "plan year state should be active" do
        expect(plan_year.aasm_state).to eq 'terminated' # before update
        expect(enrollment_terminated.aasm_state).to eq 'coverage_terminated'
        expect(ce_benefit_group_assignment.end_on).to eq plan_year.end_on
        subject.migrate

        plan_year.reload
        enrollment_terminated.reload
        ce_benefit_group_assignment.reload

        expect(plan_year.aasm_state).to eq 'active' # after update
        expect(plan_year.end_on).to eq plan_year.start_on + 364.days
        expect(plan_year.terminated_on).to eq nil

        expect(enrollment_terminated.aasm_state).to eq 'coverage_enrolled'
        expect(enrollment_terminated.terminated_on).to eq nil
        expect(enrollment_terminated.termination_submitted_on).to eq nil

        expect(ce_benefit_group_assignment.end_on).to eq nil
        expect(ce_benefit_group_assignment.aasm_state).to eq "coverage_selected"
        expect(ce_benefit_group_assignment.is_active).to eq true
      end

      it "should not reinstate cancelled plan year" do
        end_on = plan_year.end_on
        terminated_on = plan_year.terminated_on
        plan_year.update_attributes!(aasm_state:'canceled')
        subject.migrate
        plan_year.reload
        expect(plan_year.aasm_state).to eq 'canceled'
        expect(plan_year.end_on).to eq end_on
        expect(plan_year.terminated_on).to eq terminated_on
      end


    end

    context "on reinstate of plan year with end date passed and has renewing plan year cancelled" do

      let!(:open_enrollment_start_on) {TimeKeeper.date_of_record.beginning_of_month - 13.months}
      let!(:open_enrollment_end_on) {open_enrollment_start_on + 13.days }
      let(:start_on) {TimeKeeper.date_of_record.beginning_of_month - 1.year}
      let(:end_on) {TimeKeeper.date_of_record.end_of_month - 3.month}

      let!(:benefit_group) { FactoryGirl.build(:benefit_group)}
      let!(:plan_year) { FactoryGirl.build(:plan_year, aasm_state:'terminated', open_enrollment_start_on:open_enrollment_start_on,open_enrollment_end_on:open_enrollment_end_on,start_on:start_on, end_on:end_on,terminated_on:end_on,benefit_groups:[benefit_group]) }


      let!(:renew_benefit_group) { FactoryGirl.build(:benefit_group)}
      let!(:renewing_plan_year) { FactoryGirl.build(:plan_year, aasm_state:'renewing_canceled',benefit_groups:[renew_benefit_group]) }

      let!(:terminated_enrollment) { FactoryGirl.create(:hbx_enrollment, :terminated, effective_on:plan_year.start_on, terminated_on: plan_year.end_on, benefit_group_id:benefit_group.id, household: family.active_household, terminate_reason: "")}
      let!(:canceled_enrollment) { FactoryGirl.create(:hbx_enrollment, effective_on:renewing_plan_year.start_on, benefit_group_id:renew_benefit_group.id, household: family.active_household, aasm_state:'coverage_canceled')}

      let!(:benefit_group_assignment) { FactoryGirl.build(:benefit_group_assignment, aasm_state:'coverage_selected',hbx_enrollment_id:terminated_enrollment.id,benefit_group_id:benefit_group.id,start_on:start_on,end_on:end_on) }
      let!(:renewal_benefit_group_assignment) { FactoryGirl.build(:benefit_group_assignment, hbx_enrollment_id:canceled_enrollment.id, benefit_group_id:renew_benefit_group.id, is_active:false) }


      let!(:emp_plan_years) {  employer_profile.plan_years << [renewing_plan_year,plan_year] }
      let!(:ce_benefit_group_assignments) {census_employee.benefit_group_assignments << [renewal_benefit_group_assignment,benefit_group_assignment]}


      it "should expire plan year, enrollments & benefit_group_assignment when plan year end date passed on reinstate " do

        expect(plan_year.aasm_state).to eq 'terminated'  # before update
        expect(terminated_enrollment.aasm_state).to eq 'coverage_terminated'
        expect(benefit_group_assignment.end_on).to eq plan_year.end_on
        subject.migrate

        plan_year.reload
        terminated_enrollment.reload
        benefit_group_assignment.reload

        expect(plan_year.aasm_state).to eq 'expired'   # after update
        expect(plan_year.end_on).to eq plan_year.start_on + 364.days
        expect(plan_year.terminated_on).to eq nil

        expect(terminated_enrollment.aasm_state).to eq 'coverage_expired'
        expect(terminated_enrollment.terminated_on).to eq nil
        expect(terminated_enrollment.termination_submitted_on).to eq nil

        expect(benefit_group_assignment.end_on).to eq plan_year.end_on
        expect(benefit_group_assignment.aasm_state).to eq "coverage_expired"
        expect(benefit_group_assignment.is_active).to eq false

      end

      it "renewing plan year, enrollments & benefit_group_assignment should be active " do

        allow_any_instance_of(PlanYear).to receive(:is_enrollment_valid?).and_return(true)
        expect(renewing_plan_year.aasm_state).to eq 'renewing_canceled'   # before update
        expect(canceled_enrollment.aasm_state).to eq 'coverage_canceled'
        subject.migrate

        renewing_plan_year.reload
        canceled_enrollment.reload
        renewal_benefit_group_assignment.reload

        expect(renewing_plan_year.aasm_state).to eq 'active'    # after update
        expect(renewing_plan_year.end_on).to eq renewing_plan_year.end_on
        expect(renewing_plan_year.terminated_on).to eq nil

        expect(canceled_enrollment.aasm_state).to eq 'coverage_enrolled'
        expect(canceled_enrollment.terminated_on).to eq nil
        expect(canceled_enrollment.termination_submitted_on).to eq nil

        expect(renewal_benefit_group_assignment.end_on).to eq nil
        expect(renewal_benefit_group_assignment.aasm_state).to eq "coverage_selected"
        expect(renewal_benefit_group_assignment.is_active).to eq true
      end

      it "renewing plan year not force published, plan year should be moved to renewing draft state " do
        allow(ENV).to receive(:[]).with("renewing_force_publish").and_return(false)
        expect(renewing_plan_year.aasm_state).to eq 'renewing_canceled'   # before update
        subject.migrate

        renewing_plan_year.reload
        expect(renewing_plan_year.aasm_state).to eq 'renewing_draft'    # after update
      end
    end
  end
end
