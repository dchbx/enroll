require 'rails_helper'

RSpec.describe Factories::FamilyEnrollmentCloneFactory, :type => :model do

  let(:renewal_start) { TimeKeeper.date_of_record.next_month.beginning_of_month }

  let!(:renewal_plan) {
    FactoryGirl.create(:plan, :with_premium_tables, market: 'shop', metal_level: 'gold', active_year: renewal_start.year, hios_id: "11111111122302-01", csr_variant_id: "01")
  }

  let!(:plan) {
    FactoryGirl.create(:plan, :with_premium_tables, market: 'shop', metal_level: 'gold', active_year: renewal_start.year - 1, hios_id: "11111111122302-01", csr_variant_id: "01", renewal_plan_id: renewal_plan.id)
  }

  let!(:employer_profile) {
    create(:employer_with_renewing_planyear, start_on: renewal_start, renewal_plan_year_state: 'renewing_enrolling', reference_plan_id: plan.id)
  }
  let(:active_plan_year) { employer_profile.active_plan_year }
  let(:benefit_group) { active_plan_year.benefit_groups.first }
  let(:coverage_terminated_on) { TimeKeeper.date_of_record.prev_month.end_of_month }

  let!(:build_plan_years_and_employees) {
    owner = FactoryGirl.create :census_employee, :owner, employer_profile: employer_profile
    employee_role = FactoryGirl.create :employee_role, employer_profile: employer_profile
    employee = FactoryGirl.create :census_employee, employer_profile: employer_profile
    employee.update(aasm_state: 'cobra_linked', cobra_begin_date: coverage_terminated_on.next_day, coverage_terminated_on: coverage_terminated_on, employee_role_id: employee_role.id)
    employee.add_benefit_group_assignment benefit_group, benefit_group.start_on
  }
  
  let(:ce) {
    employer_profile.census_employees.non_business_owner.first
  }

  let!(:family) {
    person = FactoryGirl.create(:person, last_name: ce.last_name, first_name: ce.first_name)
    employee_role = FactoryGirl.create(:employee_role, person: person, census_employee: ce, employer_profile: employer_profile)
    ce.update_attributes({employee_role: employee_role})
    family_rec = Family.find_or_build_from_employee_role(employee_role)
    hbx_enrollment_mem=FactoryGirl.build(:hbx_enrollment_member, eligibility_date:Time.now,applicant_id:person.primary_family.family_members.first.id,coverage_start_on:ce.active_benefit_group_assignment.benefit_group.start_on)

    FactoryGirl.create(:hbx_enrollment,
      household: person.primary_family.active_household,
      coverage_kind: "health",
      effective_on: ce.active_benefit_group_assignment.benefit_group.start_on,
      enrollment_kind: "open_enrollment",
      kind: "employer_sponsored",
      submitted_at: benefit_group.start_on - 20.days,
      benefit_group_id: benefit_group.id,
      employee_role_id: person.active_employee_roles.first.id,
      benefit_group_assignment_id: ce.active_benefit_group_assignment.id,
      plan_id: plan.id,
      aasm_state: 'coverage_terminated',
      external_enrollment: external_enrollment,
      hbx_enrollment_members:[hbx_enrollment_mem]
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

  context 'family under renewing employer' do
    let(:external_enrollment) { false }

    it 'should recive cobra enrollment' do
      expect(family.enrollments.size).to eq 1
      expect(family.enrollments.map(&:kind)).not_to include('employer_sponsored_cobra')
      generate_cobra_enrollment
      expect(family.enrollments.by_coverage_kind('health').size).to eq 3
      expect(family.enrollments.map(&:kind)).to include('employer_sponsored_cobra')
    end

    it "the effective_on of cobra enrollment should greater than start_on of plan_year" do
      generate_cobra_enrollment
      cobra_enrollment = family.enrollments.detect {|e| e.is_cobra_status?}
      expect(cobra_enrollment.effective_on).to be >= cobra_enrollment.benefit_group.valid_plan_year.start_on
      expect(cobra_enrollment.external_enrollment).to be_falsey
    end
  end

  context 'family under conversion employer' do
    let(:external_enrollment) { true } 

    before do
      employer_profile.update_attributes(profile_source: 'conversion', registered_on: renewal_start - 3.months)
    end

    it 'should generate external cobra enrollment' do
      generate_cobra_enrollment
      cobra_enrollment = family.enrollments.detect {|e| e.is_cobra_status?}
      expect(cobra_enrollment.external_enrollment).to be_truthy
      expect(cobra_enrollment.coverage_selected?).to be_truthy
      expect(cobra_enrollment.effective_on).to eq coverage_terminated_on.next_day
    end

    it 'cobra enrollment member coverage_start_on should cloned enrollment effective_on' do
      generate_cobra_enrollment
      cobra_enrollment = family.enrollments.detect {|e| e.is_cobra_status?}
      expect(cobra_enrollment.hbx_enrollment_members.first.coverage_start_on).to eq family.enrollments.first.effective_on
    end

  end
end
