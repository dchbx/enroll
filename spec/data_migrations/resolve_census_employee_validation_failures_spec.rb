require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "resolve_census_employee_validation_failures")

describe ResolveCensusEmployeeValidationFailures do

  let(:given_task_name) { "resolve_census_employee_validation_failures" }
  subject { ResolveCensusEmployeeValidationFailures.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe "employer profile with employees present" do

    let(:effective_on) { TimeKeeper.date_of_record.beginning_of_year }
    let!(:plan) { FactoryGirl.create(:plan, market: 'shop', metal_level: 'gold', active_year: effective_on.year, hios_id: "11111111122302-01", csr_variant_id: "01", coverage_kind: 'health') }

    context 'Renewing employer exists with published plan year' do

      let!(:employer) {
        FactoryGirl.create(:employer_with_planyear, start_on: effective_on, reference_plan_id: plan.id, plan_year_state: 'active')
      }

      let(:benefit_group) { employer.active_plan_year.benefit_groups.first }

      let(:employees) {
        FactoryGirl.create_list(:census_employee_with_active_and_renewal_assignment, 2, hired_on: (TimeKeeper.date_of_record - 2.years), employer_profile: employer, 
          benefit_group: benefit_group)
      }

      context 'when employee exists with active coverage' do
        let(:employee) {
          employee_role = FactoryGirl.create(:employee_role, person: person, census_employee: ce, employer_profile: employer)
          ce.update_attributes({employee_role: employee_role})
          employee_role
        }
       
        let!(:family) { FactoryGirl.create(:family, :with_family_members, person: person, people: [person]) }
        let(:person) { FactoryGirl.create(:person, last_name: ce.last_name, first_name: ce.first_name) }
        let(:ce) { employees[0] }
 
        let!(:enrollment) {
          FactoryGirl.create(:hbx_enrollment,:with_enrollment_members,
            enrollment_members: family.family_members,
            household: family.active_household,
            coverage_kind: 'health',
            effective_on: effective_on.prev_year,
            enrollment_kind: 'open_enrollment',
            kind: "employer_sponsored",
            benefit_group_id: benefit_group.id,
            employee_role_id: employee.id,
            benefit_group_assignment_id: ce.active_benefit_group_assignment.id,
            plan_id: benefit_group.reference_plan.id,
            aasm_state: 'coverage_selected'
          )
        }

        context "when census employee pointing to incorrect enrollment id" do

          before do 
            assignment = ce.active_benefit_group_assignment
            assignment.hbx_enrollment_id = '51212121212'
            assignment.aasm_state = 'coverage_selected'
            assignment.save(:validate => false)
          end

          it 'should remove the incorrect enrollment id' do
            assignment = ce.active_benefit_group_assignment
            subject.migrate
            assignment.reload
            expect(assignment.initialized?).to be_truthy
            expect(assignment.hbx_enrollment_id).to be_nil
          end
        end

        context 'when census employee missing benefit group assignment' do

          it 'should assign default benefit group assignment' do 
            ce.active_benefit_group_assignment.delete
            subject.migrate
            ce.reload
            expect(ce.active_benefit_group_assignment.present?).to be_truthy
          end
        end
      end
    end
  end
end