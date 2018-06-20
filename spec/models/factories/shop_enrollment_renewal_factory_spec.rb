require 'rails_helper'

RSpec.describe Factories::ShopEnrollmentRenewalFactory, :type => :model do

  describe ".generate_passive_renewal" do

    let(:effective_on) { TimeKeeper.date_of_record.end_of_month.next_day }
 
    let!(:renewal_plan) { FactoryGirl.create(:plan, market: 'shop', metal_level: 'gold', active_year: effective_on.year, hios_id: "11111111122302-01", csr_variant_id: "01", coverage_kind: 'health') }
    let!(:plan) { FactoryGirl.create(:plan, market: 'shop', metal_level: 'gold', active_year: effective_on.year - 1, hios_id: "11111111122302-01", csr_variant_id: "01", renewal_plan_id: renewal_plan.id, coverage_kind: 'health') }

    let!(:dental_renewal_plan) { FactoryGirl.create(:plan, market: 'shop', metal_level: 'dental', active_year: effective_on.year, hios_id: "91111111122302", coverage_kind: 'dental', dental_level: 'high') }
    let!(:dental_plan) { FactoryGirl.create(:plan, market: 'shop', metal_level: 'dental', active_year: effective_on.year - 1, hios_id: "91111111122302",  renewal_plan_id: dental_renewal_plan.id, coverage_kind: 'dental', dental_level: 'high') }

    let(:generate_passive_renewal) {
      Factories::ShopEnrollmentRenewalFactory.new({
        family: family, 
        census_employee: employee.census_employee.reload, 
        employer: renewing_employer, 
        renewing_plan_year: renewing_employer.renewing_plan_year, 
        enrollment: enrollment,
        is_waiver: false,
        coverage_kind: 'health'
      }).generate_passive_renewal
    }

    context 'Renewing employer exists with published plan year' do

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

      context 'when employee exists with active coverage' do
        let(:employee) {
          employee_role = FactoryGirl.create(:employee_role, person: person, census_employee: ce, employer_profile: renewing_employer)
          ce.update_attributes({employee_role: employee_role})
          employee_role
        }
       
        let!(:family) { FactoryGirl.create(:family, :with_family_members, person: person, people: family_members) }
        let(:person) { FactoryGirl.create(:person, last_name: ce.last_name, first_name: ce.first_name, person_relationships: family_relationships) }
        let(:ce) { renewing_employees[0] }
        let(:family_members) { [person, spouse, child]}
        let(:spouse) { FactoryGirl.create(:person, dob: TimeKeeper.date_of_record - 50.years) }
        let(:child)  { FactoryGirl.create(:person, dob: child_age) }
        let(:family_relationships) { [PersonRelationship.new(relative: spouse, kind: "spouse"), PersonRelationship.new(relative: child, kind: "child")] }

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

        let(:child_age) { TimeKeeper.date_of_record - 10.years }

        context 'when employer not offering coverage for dependent' do

          before do
            renewal_benefit_group.relationship_benefits.where(:relationship => 'spouse').first.update(:offered => false)
          end

          it 'should not include dependent in passive renewal' do
            expect(family.active_household.hbx_enrollments.renewing.empty?).to be_truthy
            expect(enrollment.hbx_enrollment_members.size).to eq 3
            generate_passive_renewal

            health_renewal = family.active_household.hbx_enrollments.by_coverage_kind('health').renewing.first

            expect(health_renewal.present?).to be_truthy
            expect(health_renewal.hbx_enrollment_members.size).to eq 2
            expect(health_renewal.hbx_enrollment_members.collect{|e| e.hbx_id}).to eq [person.hbx_id, child.hbx_id]
          end 
        end

        context 'when child aged off' do
          let(:child_age) { TimeKeeper.date_of_record - 27.years }

          it 'should not include child in passive renewal' do
            expect(family.active_household.hbx_enrollments.renewing.empty?).to be_truthy
            expect(enrollment.hbx_enrollment_members.size).to eq 3
            generate_passive_renewal

            health_renewal = family.active_household.hbx_enrollments.by_coverage_kind('health').renewing.first

            expect(health_renewal.present?).to be_truthy
            expect(health_renewal.hbx_enrollment_members.size).to eq 2
            expect(health_renewal.hbx_enrollment_members.collect{|e| e.hbx_id}).to eq [person.hbx_id, spouse.hbx_id]
          end
        end

        context "should trigger state machine events after generating hbx_id for enrollment" do
          let(:generate_passive_renewal) {
            Factories::ShopEnrollmentRenewalFactory.new({
              family: family, 
              census_employee: employee.census_employee.reload, 
              employer: renewing_employer, 
              renewing_plan_year: renewing_employer.renewing_plan_year, 
              enrollment: enrollment,
              is_waiver: false,
              coverage_kind: 'health'
            }).generate_passive_renewal({aasm_event: "force_select_coverage"})
          }

          before do
            renewing_employer.renewing_plan_year.update_attribute(:open_enrollment_end_on, TimeKeeper.date_of_record + 1.day)
            generate_passive_renewal
          end

          it "should not have nil hbx_id" do
            queued_job = ActiveJob::Base.queue_adapter.enqueued_jobs.find do |job_info|
              job_info[:job] == ShopNoticesNotifierJob
            end

            expect(queued_job[:args][2]["hbx_enrollment_hbx_id"]).not_to eq nil
          end
        end
      end
    end
  end
end