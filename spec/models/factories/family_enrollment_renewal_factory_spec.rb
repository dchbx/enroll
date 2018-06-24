require 'rails_helper'

RSpec.describe Factories::FamilyEnrollmentRenewalFactory, :type => :model do

  HbxEnrollment::COVERAGE_KINDS.each do |coverage_kind|

    describe ".#{coverage_kind} renewal" do
      let(:effective_on) { TimeKeeper.date_of_record.end_of_month.next_day }
      let(:plan_metal_level) { coverage_kind == 'dental' ? 'dental' : 'gold' }
      let(:dental_level) { coverage_kind == 'dental' ? 'high' : nil}

      let!(:renewal_plan) {
        FactoryGirl.create(:plan, :with_premium_tables, market: 'shop', metal_level: plan_metal_level, active_year: effective_on.year, hios_id: "11111111122302-01", csr_variant_id: "01", coverage_kind: coverage_kind, dental_level: dental_level)
      }

      let!(:plan) {
        FactoryGirl.create(:plan, :with_premium_tables, market: 'shop', metal_level: plan_metal_level, active_year: effective_on.year - 1, hios_id: "11111111122302-01", csr_variant_id: "01", renewal_plan_id: renewal_plan.id, coverage_kind: coverage_kind, dental_level: dental_level)
      }

      let(:renewing_employer) {
        if coverage_kind == 'dental'
          FactoryGirl.create(:employer_with_renewing_planyear, start_on: effective_on, 
            renewal_plan_year_state: 'renewing_enrolling', 
            dental_reference_plan_id: plan.id, 
            dental_renewal_reference_plan_id: renewal_plan.id,
            with_dental: true
          )
        else
          FactoryGirl.create(:employer_with_renewing_planyear, start_on: effective_on, 
            renewal_plan_year_state: 'renewing_enrolling', 
            reference_plan_id: plan.id, 
            renewal_reference_plan_id: renewal_plan.id,
            )
        end
      }

      let(:renewing_employees) {
        FactoryGirl.create_list(:census_employee_with_active_and_renewal_assignment, 4, hired_on: (TimeKeeper.date_of_record - 2.years), employer_profile: renewing_employer, 
          benefit_group: renewing_employer.active_plan_year.benefit_groups.first, 
          renewal_benefit_group: renewing_employer.renewing_plan_year.benefit_groups.first)
      }

      let(:generate_renewal) {
        factory = Factories::FamilyEnrollmentRenewalFactory.new
        factory.family = current_employee.person.primary_family.reload
        factory.census_employee = current_employee.census_employee.reload
        factory.employer = renewing_employer.reload
        factory.renewing_plan_year = renewing_employer.renewing_plan_year.reload
        factory.renew
      }

      context 'Renewing employer exists with published plan year' do

        let(:current_family) { current_employee.person.primary_family }
    
        context 'when family have active coverage' do
          let(:employee_A) {
            ce = renewing_employees[0]
            create_person(ce, renewing_employer)
          }

          let!(:employee_A_enrollments) {
            create_enrollment(family: employee_A.person.primary_family, benefit_group_assignment: employee_A.census_employee.active_benefit_group_assignment, employee_role: employee_A, submitted_at: effective_on.prev_year, coverage_kind: coverage_kind)
          }

          let(:current_employee) {
            employee_A
          }

          context 'when employer offering renewal plans' do
            it 'should renew the coverage' do
              expect(current_family.active_household.hbx_enrollments.renewing.by_coverage_kind(coverage_kind).present?).to be_falsey
              generate_renewal
              expect(current_family.active_household.hbx_enrollments.renewing.by_coverage_kind(coverage_kind).present?).to be_truthy
            end
          end

          context 'when employer changed plan offerings and renewal plans not offered' do
            let!(:new_renewal_plan) {
              FactoryGirl.create(:plan, :with_premium_tables, market: 'shop', metal_level: plan_metal_level, active_year: effective_on.year, hios_id: "11111111122301-01", csr_variant_id: "01", coverage_kind: coverage_kind, dental_level: dental_level)
            }

            before do
              benefit_group = renewing_employer.renewing_plan_year.benefit_groups.first
              if coverage_kind == 'dental'
                benefit_group.update_attributes({dental_reference_plan_id: new_renewal_plan.id, elected_dental_plan_ids: [new_renewal_plan.id]})
              else
                benefit_group.update_attributes({reference_plan_id: new_renewal_plan.id, elected_plan_ids: [new_renewal_plan.id]})
              end
            end

            it 'should not generate passive waiver' do
              generate_renewal
              passive_waiver = current_family.active_household.hbx_enrollments.by_coverage_kind(coverage_kind).where(:aasm_state => 'renewing_waived').first
              expect(passive_waiver.present?).to be_falsey
            end

            context 'when an employee has metlife/delta dental plan in 2017-2018' do
              let!(:organization) { FactoryGirl.create(:organization, legal_name: "Delta Dental") }
              let!(:carrier_profile) {FactoryGirl.create(:carrier_profile, organization: organization, abbrev: "DDPA")}
              let!(:plan) {
                FactoryGirl.create(:plan, :with_premium_tables, name: "Delta Dental PPO Basic Plan for Families", market: 'shop', metal_level: plan_metal_level, active_year: effective_on.year - 1, hios_id: "11111111122302-01", csr_variant_id: "01", renewal_plan_id: renewal_plan.id, coverage_kind: coverage_kind, dental_level: dental_level, carrier_profile: carrier_profile)
              }

              it 'should trigger dental carrier exiting notice' do
                factory = Factories::FamilyEnrollmentRenewalFactory.new
                factory.family = current_employee.person.primary_family.reload
                factory.census_employee = current_employee.census_employee.reload
                factory.employer = renewing_employer.reload
                factory.renewing_plan_year = renewing_employer.renewing_plan_year.reload
                expect(factory).to receive(:trigger_notice_dental) if coverage_kind == 'dental'
                factory.renew
              end
            end

            context 'when an employee has NON - metlife/delta dental plan' do
              it 'should not trigger dental carrier exiting notice' do
                factory = Factories::FamilyEnrollmentRenewalFactory.new
                factory.family = current_employee.person.primary_family.reload
                factory.census_employee = current_employee.census_employee.reload
                factory.employer = renewing_employer.reload
                factory.renewing_plan_year = renewing_employer.renewing_plan_year.reload
                expect(factory).not_to receive(:trigger_notice_dental)
                factory.renew
              end
            end
          end
        end

        context 'when family actively renewed coverage' do
          let(:employee_B) {
            ce = renewing_employees[1]
            create_person(ce, renewing_employer)
          }

          let!(:employee_B_enrollments) {
            create_enrollment(family: employee_B.person.primary_family, benefit_group_assignment: employee_B.census_employee.active_benefit_group_assignment, employee_role: employee_B, submitted_at: effective_on.prev_year, coverage_kind: coverage_kind)
            create_enrollment(family: employee_B.person.primary_family, benefit_group_assignment: employee_B.census_employee.renewal_benefit_group_assignment, employee_role: employee_B, submitted_at: effective_on - 20.days, status: 'coverage_selected', coverage_kind: coverage_kind) 
          }

          let(:current_employee) {
            employee_B
          }

          it 'should not change active renewal' do
            generate_renewal
            active_renewal = current_family.active_household.hbx_enrollments.by_coverage_kind(coverage_kind).where(:effective_on => effective_on).first
            expect(active_renewal.coverage_selected?).to be_truthy
          end

          it 'should not generate passive renewal/waiver' do
            generate_renewal
            expect(current_family.active_household.hbx_enrollments.by_coverage_kind(coverage_kind).where(:aasm_state => 'renewing_waived').empty?).to be_truthy
            expect(current_family.active_household.hbx_enrollments.renewing.empty?).to be_truthy
          end
        end

        context 'when family already passively renewed' do
          let(:employee_C) {
            ce = renewing_employees[2]
            create_person(ce, renewing_employer)
          }

          let!(:employee_C_enrollments) {
            create_enrollment(family: employee_C.person.primary_family, benefit_group_assignment: employee_C.census_employee.active_benefit_group_assignment, employee_role: employee_C, submitted_at: effective_on.prev_year, coverage_kind: coverage_kind)
            create_enrollment(family: employee_C.person.primary_family, benefit_group_assignment: employee_C.census_employee.renewal_benefit_group_assignment, employee_role: employee_C, submitted_at: effective_on - 20.days, status: 'auto_renewing', coverage_kind: coverage_kind) 
          }

          let(:current_employee) {
            employee_C
          }

          it 'should not generate new passive renewal' do
            passive_renewal = current_family.active_household.hbx_enrollments.renewing.by_coverage_kind(coverage_kind).first
            expect(passive_renewal.present?).to be_truthy
            generate_renewal
            passive_renewal.reload
            expect(passive_renewal.auto_renewing?).to be_truthy
            expect(current_family.active_household.hbx_enrollments.renewing.size).to eq 1
            expect(current_family.active_household.hbx_enrollments.by_coverage_kind(coverage_kind).where(:aasm_state => 'renewing_waived').empty?).to be_truthy
          end
        end

        context 'when family do not active coverage' do
          let(:employee_D) {
            ce = renewing_employees[3]
            create_person(ce, renewing_employer)
          }

          let(:current_employee) {
            employee_D
          }

          it 'should generate not passive waiver' do
            generate_renewal
            expect(current_family.active_household.hbx_enrollments.by_coverage_kind(coverage_kind).where(:aasm_state => 'renewing_waived').empty?).to be_truthy            
          end 
        end
      end

      def create_person(ce, employer_profile)
        person = FactoryGirl.create(:person, last_name: ce.last_name, first_name: ce.first_name)
        employee_role = FactoryGirl.create(:employee_role, person: person, census_employee: ce, employer_profile: employer_profile)
        ce.update_attributes({employee_role: employee_role})
        Family.find_or_build_from_employee_role(employee_role)
        employee_role
      end

      def create_enrollment(family: nil, benefit_group_assignment: nil, employee_role: nil, status: 'coverage_selected', submitted_at: nil, enrollment_kind: 'open_enrollment', effective_date: nil, coverage_kind: 'health')
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
          plan_id: (coverage_kind == 'dental' ? benefit_group.dental_reference_plan_id : benefit_group.reference_plan.id),
          aasm_state: status
          )
      end
    end
  end
end