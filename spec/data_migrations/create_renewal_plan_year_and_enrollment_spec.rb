require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "create_renewal_plan_year_and_enrollment")


describe CreateRenewalPlanYearAndEnrollment, dbclean: :after_each do

  let(:given_task_name) { "create_renewal_plan_year_and_passive_renewals" }
  subject { CreateRenewalPlanYearAndEnrollment.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe "create_renewal_plan_year_and_passive_renewals", dbclean: :after_each do

    let (:renewal_plan) {FactoryGirl.create(:plan, active_year:TimeKeeper.date_of_record.year + 1)}
    let (:active_benefit_group_ref_plan) {FactoryGirl.create(:plan, active_year:TimeKeeper.date_of_record.year - 1,renewal_plan_id:renewal_plan.id)}

    let(:benefit_group) { FactoryGirl.create(:benefit_group, reference_plan_id:active_benefit_group_ref_plan.id, elected_plan_ids:[active_benefit_group_ref_plan.id]) }
    let (:active_plan_year){ FactoryGirl.build(:plan_year,start_on:TimeKeeper.date_of_record.next_month.beginning_of_month - 1.year, end_on:TimeKeeper.date_of_record.end_of_month,aasm_state: "active",benefit_groups:[benefit_group]) }
    let(:employer_profile){ FactoryGirl.create(:employer_profile, plan_years: [active_plan_year]) }
    let(:organization)  { employer_profile.organization}

    let(:benefit_group_assignment) { FactoryGirl.build(:benefit_group_assignment, benefit_group: benefit_group)}
    let(:employee_role) { FactoryGirl.create(:employee_role)}
    let(:census_employee) { FactoryGirl.create(:census_employee,employer_profile: employer_profile,:benefit_group_assignments => [benefit_group_assignment],employee_role_id:employee_role.id) }

    let(:person) {FactoryGirl.create(:person,ssn:census_employee.ssn)}
    let(:family) { FactoryGirl.create(:family, :with_primary_family_member,person:person)}
    let(:active_household) {family.active_household}
    let(:enrollment) { FactoryGirl.create(:hbx_enrollment, plan_id:active_benefit_group_ref_plan.id,benefit_group_id: benefit_group.id, household:family.active_household,benefit_group_assignment_id: benefit_group_assignment.id, employee_role_id:employee_role.id)}
    let(:plan_years) {employer_profile.plan_years}

    before(:each) do
      active_household.hbx_enrollments =[enrollment]
      active_household.save!
      allow(ShopNoticesNotifierJob).to receive(:perform_later).and_return true
    end


    context "when renewal_plan_year" do

      before(:each) do
        allow(ENV).to receive(:[]).with("fein").and_return(organization.fein)
        allow(ENV).to receive(:[]).with("action").and_return("renewal_plan_year")
      end

      it "should create renewing draft plan year" do
        expect(organization.employer_profile.plan_years.map(&:aasm_state)).to eq ['active']
        subject.migrate
        employer_profile.reload
        expect(organization.employer_profile.plan_years.map(&:aasm_state)).to eq ['active','renewing_draft']
        expect(family.active_household.hbx_enrollments.map(&:aasm_state)).to eq ['coverage_selected']
      end
    end

    context "when renewal_plan_year_passive_renewal" do

      before(:each) do
        allow(ENV).to receive(:[]).with("fein").and_return(organization.fein)
        allow(ENV).to receive(:[]).with("action").and_return("renewal_plan_year_passive_renewal")
      end

      it "should create renewing plan year and passive enrollments" do
        expect(employer_profile.plan_years.map(&:aasm_state)).to eq ['active']
        expect(family.active_household.hbx_enrollments.map(&:aasm_state)).to eq ['coverage_selected']
        subject.migrate
        employer_profile.reload
        active_household.reload
        expect(employer_profile.plan_years.map(&:aasm_state)).to eq ['active','renewing_enrolling']
        expect(family.active_household.hbx_enrollments.map(&:aasm_state)).to eq ['coverage_selected','auto_renewing']
      end
    end

    context "trigger_renewal_py_for_employers" do

      before(:each) do
        allow(ENV).to receive(:[]).with("start_on").and_return(active_plan_year.start_on)
        allow(ENV).to receive(:[]).with("action").and_return("trigger_renewal_py_for_employers")
      end

      it "should create renewing plan year" do
        expect(organization.employer_profile.plan_years.map(&:aasm_state)).to eq ['active']
        subject.migrate
        employer_profile.reload
        expect(employer_profile.plan_years.map(&:aasm_state)).to eq ['active','renewing_draft']
      end
    end
  end

end

