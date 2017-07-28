require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "populate_employee_role_on_enrollments")

describe PopulateEmployeeRoleOnEnrollments do

  let(:given_task_name) { "populate_employee_role_on_enrollments" }
  subject { PopulateEmployeeRoleOnEnrollments.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe "employee exists with waived coverages" do

    let(:effective_on) { TimeKeeper.date_of_record.end_of_month.next_day }
 
    let!(:renewal_plan) { FactoryGirl.create(:plan, market: 'shop', metal_level: 'gold', active_year: effective_on.year, hios_id: "11111111122302-01", csr_variant_id: "01", coverage_kind: 'health') }
    let!(:plan) { FactoryGirl.create(:plan, market: 'shop', metal_level: 'gold', active_year: effective_on.year - 1, hios_id: "11111111122302-01", csr_variant_id: "01", renewal_plan_id: renewal_plan.id, coverage_kind: 'health') }

    let!(:dental_renewal_plan) { FactoryGirl.create(:plan, market: 'shop', metal_level: 'dental', active_year: effective_on.year, hios_id: "91111111122302", coverage_kind: 'dental', dental_level: 'high') }
    let!(:dental_plan) { FactoryGirl.create(:plan, market: 'shop', metal_level: 'dental', active_year: effective_on.year - 1, hios_id: "91111111122302",  renewal_plan_id: dental_renewal_plan.id, coverage_kind: 'dental', dental_level: 'high') }

    let(:renewing_employer) {
      FactoryGirl.create(:employer_with_renewing_planyear, start_on: effective_on, 
        renewal_plan_year_state: 'renewing_enrolling',
        reference_plan_id: plan.id,
        renewal_reference_plan_id: renewal_plan.id,
        dental_reference_plan_id: dental_plan.id, 
        dental_renewal_reference_plan_id: dental_renewal_plan.id,
        with_dental: true
        )
    }
    let(:benefit_group) { renewing_employer.active_plan_year.benefit_groups.first }
    let(:renewal_benefit_group) { renewing_employer.renewing_plan_year.benefit_groups.first }
    let(:renewing_employees) {
      FactoryGirl.create_list(:census_employee_with_active_and_renewal_assignment, 2, hired_on: (TimeKeeper.date_of_record - 2.years), employer_profile: renewing_employer, 
        benefit_group: benefit_group, renewal_benefit_group: renewal_benefit_group)
    }

    let(:ce) { renewing_employees[0] }

    let!(:employee) {
      employee_role = FactoryGirl.create(:employee_role, person: person, census_employee: ce, employer_profile: renewing_employer)
      ce.update_attributes({employee_role: employee_role})
      employee_role
    }

    let!(:family) { FactoryGirl.create(:family, :with_family_members, person: person, people: [person]) }
    let(:person) { FactoryGirl.create(:person, last_name: ce.last_name, first_name: ce.first_name) }

    before do
      allow(ENV).to receive(:[]).with('effective_on').and_return effective_on.strftime('%m/%d/%Y')
    end

    context 'missing employee role on health waiver' do 

      let(:health_waiver) { FactoryGirl.create(:hbx_enrollment,
        household: family.active_household,
        coverage_kind: 'health',
        effective_on: renewal_benefit_group.start_on,
        kind: "employer_sponsored",
        benefit_group_id: renewal_benefit_group.id,
        employee_role_id: nil,
        benefit_group_assignment_id: ce.renewal_benefit_group_assignment.id,
        plan_id: benefit_group.reference_plan.id,
        aasm_state: 'renewing_waived'
        )
      }

      it 'should set missing employee role' do
        expect(health_waiver.employee_role_id).to be_nil
        subject.migrate
        health_waiver.reload
        expect(health_waiver.employee_role_id).to eq employee.id
      end
    end

    context 'missing employee role on dental waiver' do 

      let(:dental_waiver) { FactoryGirl.create(:hbx_enrollment,
        household: family.active_household,
        coverage_kind: 'dental',
        effective_on: renewal_benefit_group.start_on,
        kind: "employer_sponsored",
        benefit_group_id: renewal_benefit_group.id,
        employee_role_id: nil,
        benefit_group_assignment_id: ce.renewal_benefit_group_assignment.id,
        plan_id: benefit_group.dental_reference_plan.id,
        aasm_state: 'renewing_waived'
        )
      }

      it 'should set missing employee role' do
        expect(dental_waiver.employee_role_id).to be_nil
        subject.migrate
        dental_waiver.reload
        expect(dental_waiver.employee_role_id).to eq employee.id
      end
    end
  end
end