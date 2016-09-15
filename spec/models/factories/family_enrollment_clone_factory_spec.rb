require 'rails_helper'

RSpec.describe Factories::FamilyEnrollmentCloneFactory, :type => :model do
  context 'Family under active employer' do
    let(:renewal_year) { (TimeKeeper.date_of_record.end_of_month + 1.day + 2.months).year }

    let!(:renewal_plan) {
      FactoryGirl.create(:plan, :with_premium_tables, market: 'shop', metal_level: 'gold', active_year: renewal_year, hios_id: "11111111122302-01", csr_variant_id: "01")
    }

    let!(:plan) {
      FactoryGirl.create(:plan, :with_premium_tables, market: 'shop', metal_level: 'gold', active_year: renewal_year - 1, hios_id: "11111111122302-01", csr_variant_id: "01", renewal_plan_id: renewal_plan.id)
    }

    let!(:organization) { 
      org = FactoryGirl.create :organization, legal_name: "Corp 1" 
      employer_profile = FactoryGirl.create :employer_profile, organization: org
      FactoryGirl.create(:qualifying_life_event_kind, market_kind: "shop")
      org.reload
    }

    let(:employer_profile) { organization.employer_profile }

    let!(:build_plan_years_and_employees) {
      owner = FactoryGirl.create :census_employee, :owner, employer_profile: employer_profile
      employee_role = FactoryGirl.create :employee_role, employer_profile: employer_profile
      employee = FactoryGirl.create :census_employee, employer_profile: employer_profile
      employee.update(aasm_state: 'cobra_linked', cobra_begin_date: TimeKeeper.date_of_record, coverage_terminated_on: TimeKeeper.date_of_record - 5.days, employee_role_id: employee_role.id)

      benefit_group = FactoryGirl.create :benefit_group, plan_year: active_plan_year, reference_plan_id: plan.id
      employee.add_benefit_group_assignment benefit_group, benefit_group.start_on
    }
      
    let(:open_enrollment_start_on) { TimeKeeper.date_of_record.end_of_month + 1.day }
    let(:open_enrollment_end_on) { open_enrollment_start_on.next_month + 12.days }
    let(:start_on) { open_enrollment_start_on + 2.months }
    let(:end_on) { start_on + 1.year - 1.day }
  
    let(:active_plan_year) {
      FactoryGirl.create :plan_year, employer_profile: employer_profile, start_on: start_on - 1.year, end_on: end_on - 1.year, open_enrollment_start_on: open_enrollment_start_on - 1.year, open_enrollment_end_on: open_enrollment_end_on - 1.year - 3.days, fte_count: 2, aasm_state: :published
    }

    let!(:ce) {
      organization.employer_profile.census_employees.non_business_owner.first
    }

    let!(:family) {
      person = FactoryGirl.create(:person, last_name: ce.last_name, first_name: ce.first_name)
      employee_role = FactoryGirl.create(:employee_role, person: person, census_employee: ce, employer_profile: organization.employer_profile)
      ce.update_attributes({employee_role: employee_role})
      family_rec = Family.find_or_build_from_employee_role(employee_role)

      FactoryGirl.create(:hbx_enrollment,
        household: person.primary_family.active_household,
        coverage_kind: "health",
        effective_on: ce.active_benefit_group_assignment.benefit_group.start_on,
        enrollment_kind: "open_enrollment",
        kind: "employer_sponsored",
        submitted_at: ce.active_benefit_group_assignment.benefit_group.start_on - 20.days,
        benefit_group_id: ce.active_benefit_group_assignment.benefit_group.id,
        employee_role_id: person.active_employee_roles.first.id,
        benefit_group_assignment_id: ce.active_benefit_group_assignment.id,
        plan_id: plan.id
        )

      family_rec.reload
    }

    let(:generate_cobra_enrollment) {
      factory = Factories::FamilyEnrollmentCloneFactory.new
      factory.family = family
      factory.census_employee = ce
      factory.enrollment = family.enrollments.first
      factory.clone_for_cobra
    }

    it 'should recive cobra enrollment' do
      expect(family.enrollments.size).to eq 1
      expect(family.enrollments.map(&:kind)).not_to include('employer_sponsored_cobra')
      generate_cobra_enrollment
      expect(family.enrollments.size).to eq 2
      expect(family.enrollments.map(&:kind)).to include('employer_sponsored_cobra')
    end
  end
end
