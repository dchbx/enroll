require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "cancel_dental_offerings_from_plan_year")

describe CancelDentalOfferingsFromPlanYear do

  let(:given_task_name) { "cancel_dental_offerings_from_plan_year" }
  subject { CancelDentalOfferingsFromPlanYear.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe "changing plan year's state", dbclean: :after_each do
    let(:organization) { FactoryGirl.create(:organization, :with_active_and_renewal_plan_years)}
    let(:census_employee) {
      ce = FactoryGirl.create :census_employee, employer_profile: organization.employer_profile, dob: TimeKeeper.date_of_record - 30.years
      person = FactoryGirl.create(:person, last_name: ce.last_name, first_name: ce.first_name)
        employee_role = FactoryGirl.create(:employee_role, person: person, census_employee: ce, employer_profile: organization.employer_profile)
        ce.update_attributes({employee_role: employee_role})
        family = Family.find_or_build_from_employee_role(employee_role)
        enrollment = HbxEnrollment.create_from(
          employee_role: employee_role,
          coverage_household: family.households.first.coverage_households.first,
          benefit_group_assignment: ce.renewal_benefit_group_assignment,
          benefit_group: organization.employer_profile.renewing_plan_year.benefit_groups.first
          )
        enrollment.update_attributes(:aasm_state => 'auto_renewing', coverage_kind: "health")

        enrollment = HbxEnrollment.create_from(
          employee_role: employee_role,
          coverage_household: family.households.first.coverage_households.first,
          benefit_group_assignment: ce.renewal_benefit_group_assignment,
          benefit_group: organization.employer_profile.renewing_plan_year.benefit_groups.first
          )
        enrollment.update_attributes(:aasm_state => 'coverage_selected', coverage_kind: "dental")

        enrollment = HbxEnrollment.create_from(
          employee_role: employee_role,
          coverage_household: family.households.first.coverage_households.first,
          benefit_group_assignment: ce.renewal_benefit_group_assignment,
          benefit_group: organization.employer_profile.renewing_plan_year.benefit_groups.first
          )
        enrollment.update_attributes(:aasm_state => 'renewing_waived', coverage_kind: "dental")
        ce
      }

    before(:each) do
      allow(ENV).to receive(:[]).with("fein").and_return(organization.fein)
      allow(ENV).to receive(:[]).with("aasm_state").and_return(organization.employer_profile.renewing_plan_year.aasm_state)
      allow(ENV).to receive(:[]).with("benefit_group_id").and_return(organization.employer_profile.renewing_plan_year.benefit_groups.first.id)
    end

    it "should cancel the dental enrollment" do
      enrollment = census_employee.employee_role.person.primary_family.active_household.hbx_enrollments.where(coverage_kind: "dental", aasm_state: "coverage_selected").first
      subject.migrate
      id = enrollment.id
      enrollment = HbxEnrollment.find(id)
      expect(enrollment.aasm_state).to eq "coverage_canceled"
    end

    it "should cancel the dental waived enrollment" do
      enrollment = census_employee.employee_role.person.primary_family.active_household.hbx_enrollments.where(coverage_kind: "dental", aasm_state: "renewing_waived").first
      subject.migrate
      id = enrollment.id
      enrollment = HbxEnrollment.find(id)
      expect(enrollment.aasm_state).to eq "coverage_canceled"
    end

    it "should not cancel the health enrollment" do
      enrollment = census_employee.employee_role.person.primary_family.active_household.hbx_enrollments.where(coverage_kind: "health").first
      expect(enrollment.aasm_state).to eq "auto_renewing"
      subject.migrate
      id = enrollment.id
      enrollment = HbxEnrollment.find(id)
      expect(enrollment.aasm_state).to eq "auto_renewing"
    end

    it "should cancel the dental offerings of the selected benefit group" do
      renewing_benefit_group = organization.employer_profile.renewing_plan_year.benefit_groups.first
      expect(renewing_benefit_group.dental_reference_plan_id).not_to eq nil
      subject.migrate
      id = renewing_benefit_group.id
      renewing_benefit_group = BenefitGroup.find(id)
      expect(renewing_benefit_group.dental_reference_plan_id).to eq nil
    end

    it "should not cancel the dental offerings of the active benefit group" do
      active_benefit_group = organization.employer_profile.plan_years.where(aasm_state: "active").first.benefit_groups.first
      expect(active_benefit_group.dental_reference_plan_id).not_to eq nil
      subject.migrate
      id = active_benefit_group.id
      active_benefit_group = BenefitGroup.find(id)
      expect(active_benefit_group.dental_reference_plan_id).not_to eq nil
    end
  end
end
