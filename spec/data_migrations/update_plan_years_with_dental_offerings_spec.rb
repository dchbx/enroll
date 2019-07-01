require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "update_plan_years_with_dental_offerings")

describe UpdatePlanYearsWithDentalOfferings do

  let(:given_task_name) { "update_plan_years_with_dental_offerings" }
  subject { UpdatePlanYearsWithDentalOfferings.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe "employer profile with employees present", :dbclean => :after_each do

    let(:effective_on) { TimeKeeper.date_of_record.end_of_month.next_day }

    let!(:renewal_plan) { FactoryBot.create(:plan, market: 'shop', metal_level: 'gold', active_year: effective_on.year, hios_id: "11111111122302-01", csr_variant_id: "01", coverage_kind: 'health') }
    let!(:plan) { FactoryBot.create(:plan, market: 'shop', metal_level: 'gold', active_year: effective_on.year - 1, hios_id: "11111111122302-01", csr_variant_id: "01", renewal_plan_id: renewal_plan.id, coverage_kind: 'health') }

    let!(:dental_renewal_plan) { FactoryBot.create(:plan, market: 'shop', metal_level: 'dental', active_year: effective_on.year, hios_id: "91111111122302", coverage_kind: 'dental', dental_level: 'high') }
    let!(:dental_plan) { FactoryBot.create(:plan, market: 'shop', metal_level: 'dental', active_year: effective_on.year - 1, hios_id: "91111111122302",  renewal_plan_id: dental_renewal_plan.id, coverage_kind: 'dental', dental_level: 'high') }

    let(:renewing_employer) {
      FactoryBot.create(:employer_with_renewing_planyear, start_on: effective_on, 
        renewal_plan_year_state: 'renewing_enrolling',
        reference_plan_id: plan.id,
        renewal_reference_plan_id: renewal_plan.id,
        dental_reference_plan_id: dental_plan.id, 
        with_dental: true
        )
    }

    let(:benefit_group) { renewing_employer.active_plan_year.benefit_groups.first }
    let(:renewal_benefit_group) { renewing_employer.renewing_plan_year.benefit_groups.first }

    let(:renewing_employees) {
      FactoryBot.create_list(:census_employee_with_active_and_renewal_assignment, 1, :old_case, hired_on: (TimeKeeper.date_of_record - 2.years), employer_profile: renewing_employer, 
        benefit_group: benefit_group, renewal_benefit_group: renewal_benefit_group)
    }

    let(:ce) { renewing_employees[0] }
    let(:employee) {
      employee_role = FactoryBot.create(:employee_role, person: person, census_employee: ce, employer_profile: renewing_employer)
      ce.update_attributes({employee_role: employee_role})
      employee_role
    }

    let!(:person) { 
      FactoryBot.create(:person, last_name: ce.last_name, first_name: ce.first_name, dob: ce.dob)
    }

    let!(:family) { FactoryBot.create(:family, :with_family_members, person: person, people: [person]) }

    context 'dental plan year and renewals missing' do

      let!(:dental_enrollment) {
        FactoryBot.create(:hbx_enrollment,:with_enrollment_members,
          enrollment_members: family.family_members,
          family: family,
          household: family.active_household,
          coverage_kind: 'dental',
          effective_on: effective_on.prev_year,
          enrollment_kind: 'open_enrollment',
          kind: "employer_sponsored",
          benefit_group_id: benefit_group.id,
          employee_role_id: employee.id,
          benefit_group_assignment_id: ce.active_benefit_group_assignment.id,
          plan_id: dental_plan.id,
          aasm_state: 'coverage_selected'
          )
      }

      before do
        allow(Person).to receive(:where).and_return([person])
        allow(person).to receive(:primary_family).and_return(family)
      end

      around do |example|
        ClimateControl.modify calender_month: effective_on.month.to_s, calender_year: effective_on.year.to_s do
          example.run
        end
      end

      it "should add dental offerings to plan year" do
        expect(renewal_benefit_group.is_offering_dental?).to be_falsey
        subject.migrate
        renewal_benefit_group.reload
        expect(renewal_benefit_group.is_offering_dental?).to be_truthy
      end

      it "should generate dental passive renewal" do
        expect(family.active_household.hbx_enrollments.where(:benefit_group_id => renewal_benefit_group.id).any?).to be_falsey
        subject.migrate
        family.reload
        renewal_enrollment = family.active_household.hbx_enrollments.by_coverage_kind('dental').where(:benefit_group_id => renewal_benefit_group.id).first
        expect(renewal_enrollment.present?).to be_truthy
        expect(renewal_enrollment.auto_renewing?).to be_truthy
        expect(renewal_enrollment.plan_id).to eq dental_plan.renewal_plan_id
      end
    end
  end
end
