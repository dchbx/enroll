require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "correct_employees_with_incorrect_waivers")

describe CorrectEmployeesWithIncorrectWaivers do

  let(:given_task_name) { "correct_employees_with_incorrect_waivers" }
  subject { CorrectEmployeesWithIncorrectWaivers.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe "employer profile with employees present" do
    let(:effective_on) { TimeKeeper.date_of_record.end_of_month.next_day }
    let(:plan_metal_level) { 'gold' }

    let!(:renewal_plan) {
      FactoryGirl.create(:plan, :with_premium_tables, market: 'shop', metal_level: plan_metal_level, active_year: effective_on.year, hios_id: "11111111122302-01", csr_variant_id: "01", coverage_kind: 'health')
    }

    let!(:plan) {
      FactoryGirl.create(:plan, :with_premium_tables, market: 'shop', metal_level: plan_metal_level, active_year: effective_on.year - 1, hios_id: "11111111122302-01", csr_variant_id: "01", renewal_plan_id: renewal_plan.id, coverage_kind: 'health')
    }

    let(:renewing_employer) {
      FactoryGirl.create(:employer_with_renewing_planyear, start_on: effective_on,
        renewal_plan_year_state: 'renewing_enrolling',
        reference_plan_id: plan.id,
        renewal_reference_plan_id: renewal_plan.id,
        )
    }

    let(:renewing_employees) {
      FactoryGirl.create_list(:census_employee_with_active_and_renewal_assignment, 4, hired_on: (TimeKeeper.date_of_record - 2.years), employer_profile: renewing_employer,
        benefit_group: renewing_employer.active_plan_year.benefit_groups.first,
        renewal_benefit_group: renewing_employer.renewing_plan_year.benefit_groups.first)
    }

    let(:current_employee) {
      ce = renewing_employees[1]
      create_person(ce, renewing_employer)
    }

    let!(:current_employee_enrollments) {
      create_enrollment(family: current_employee.person.primary_family, benefit_group_assignment: current_employee.census_employee.active_benefit_group_assignment, employee_role: current_employee, submitted_at: effective_on.prev_year)
      create_enrollment(family: current_employee.person.primary_family, benefit_group_assignment: current_employee.census_employee.active_benefit_group_assignment, employee_role: current_employee, submitted_at: effective_on.prev_year + 10.days, status: 'inactive', created_at: TimeKeeper.date_of_record.prev_day)
    }

    let(:generate_renewal) {
      factory = Factories::FamilyEnrollmentRenewalFactory.new
      factory.family = current_employee.person.primary_family.reload
      factory.census_employee = current_employee.census_employee.reload
      factory.employer = renewing_employer.reload
      factory.renewing_plan_year = renewing_employer.renewing_plan_year.reload
      factory.renew
    }

    let(:family) { current_employee.person.primary_family }

    context "when family has incorrect passive waiver", dbclean: :after_each do

      before do
        allow(ENV).to receive(:[]).with("year").and_return(renewing_employer.active_plan_year.start_on.year)
        generate_renewal
      end

      it 'should cancel passive waiver and active waiver' do
        active_waiver = family.active_household.hbx_enrollments.detect{|e| e.inactive? }
        passive_waiver = family.active_household.hbx_enrollments.detect{|e| e.renewing_waived?}
        expect(active_waiver).to be_truthy
        expect(passive_waiver).to be_truthy
        subject.migrate
        expect(active_waiver.reload.coverage_canceled?).to be_truthy
        expect(passive_waiver.reload.coverage_canceled?).to be_truthy
      end

      it 'should generate passive renewal off of active coverage' do
        expect(family.active_household.hbx_enrollments.detect{|e| e.auto_renewing?}).to be_nil
        subject.migrate
        expect(family.reload.active_household.hbx_enrollments.detect{|e| e.auto_renewing?}).not_to be_nil
      end
    end

    def create_person(ce, employer_profile)
      person = FactoryGirl.create(:person, last_name: ce.last_name, first_name: ce.first_name)
      employee_role = FactoryGirl.create(:employee_role, person: person, census_employee: ce, employer_profile: employer_profile)
      ce.update_attributes({employee_role: employee_role})
      Family.find_or_build_from_employee_role(employee_role)
      employee_role
    end

    def create_enrollment(family: nil, benefit_group_assignment: nil, employee_role: nil, status: 'coverage_selected', submitted_at: nil, enrollment_kind: 'open_enrollment', effective_date: nil, coverage_kind: 'health', created_at: nil)
      benefit_group = benefit_group_assignment.benefit_group
      FactoryGirl.create(:hbx_enrollment,:with_enrollment_members,
        enrollment_members: [family.primary_applicant],
        household: family.active_household,
        coverage_kind: coverage_kind,
        effective_on: effective_date || benefit_group.start_on,
        enrollment_kind: enrollment_kind,
        kind: "employer_sponsored",
        submitted_at: submitted_at,
        benefit_group_id: benefit_group.id,
        employee_role_id: employee_role.id,
        benefit_group_assignment_id: benefit_group_assignment.id,
        plan_id: benefit_group.reference_plan.id,
        aasm_state: status,
        created_at: created_at || TimeKeeper.date_of_record
        )
    end
  end
end
