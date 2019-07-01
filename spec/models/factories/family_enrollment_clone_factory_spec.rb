require 'rails_helper'

require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_market.rb"
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_application.rb"

RSpec.describe Factories::FamilyEnrollmentCloneFactory, :type => :model, dbclean: :after_each do

  include_context "setup benefit market with market catalogs and product packages"
  include_context "setup renewal application"
  
  let(:predecessor_application_catalog) { true }
  let!(:sponsored_benefit_package) { predecessor_application.benefit_packages[0] }
  let!(:sponsored_benefit) { sponsored_benefit_package.health_sponsored_benefit }
  let!(:product) { sponsored_benefit.reference_product }
  let!(:employer_profile) {benefit_sponsorship.profile}
  let!(:update_renewal_app) {renewal_application.update_attributes(aasm_state: :enrollment_eligible)}
  let(:coverage_terminated_on) { TimeKeeper.date_of_record.prev_month.end_of_month }
  let(:employee_role) { FactoryBot.create :employee_role, employer_profile: employer_profile }
  let!(:active_benefit_group_assignment) { FactoryBot.build(:benefit_group_assignment, benefit_package: sponsored_benefit_package)}
  let!(:renewal_benefit_group_assignment) { FactoryBot.build(:benefit_group_assignment, start_on: benefit_package.start_on, benefit_package: benefit_package)}
  let!(:ce) { FactoryBot.create :census_employee, :owner, employer_profile: employer_profile, employee_role_id: employee_role.id ,benefit_group_assignments:[active_benefit_group_assignment, renewal_benefit_group_assignment]}
  let!(:ce_update){ce.update_attributes(aasm_state: 'cobra_linked', cobra_begin_date: coverage_terminated_on.next_day, coverage_terminated_on: coverage_terminated_on)}


  let!(:family) {
    person = FactoryBot.create(:person, :with_family, last_name: ce.last_name, first_name: ce.first_name)
    employee_role = FactoryBot.create(:employee_role, person: person, census_employee: ce, employer_profile: employer_profile)
    ce.update_attributes!({employee_role: employee_role})
    family_rec = person.primary_family
    hbx_enrollment_mem = FactoryBot.build(:hbx_enrollment_member, eligibility_date:Time.now,applicant_id:person.primary_family.family_members.first.id,coverage_start_on:ce.active_benefit_group_assignment.benefit_package.start_on)
    family_rec.save!
    FactoryBot.create(
      :hbx_enrollment,
      family: family_rec,
      household: family_rec.active_household,
      coverage_kind: "health",
      effective_on: ce.active_benefit_group_assignment.benefit_package.start_on,
      enrollment_kind: "open_enrollment",
      kind: "employer_sponsored",
      submitted_at: sponsored_benefit_package.start_on - 20.days,
      sponsored_benefit_package_id: sponsored_benefit_package.id,
      sponsored_benefit_id:sponsored_benefit.id,
      rating_area: rating_area,
      product: product,
      employee_role_id: person.active_employee_roles.first.id,
      benefit_group_assignment_id: ce.active_benefit_group_assignment.id,
      aasm_state: 'coverage_terminated',
      external_enrollment: external_enrollment,
      hbx_enrollment_members:[hbx_enrollment_mem]
    )
    family_rec.reload
  }

  let!(:clone_enrollment){family.enrollments.first}

  let(:generate_cobra_enrollment) {
    factory = Factories::FamilyEnrollmentCloneFactory.new
    factory.family = family
    factory.census_employee = ce
    factory.enrollment = family.enrollments.first
    factory.clone_for_cobra
  }

  before do
    allow(::BenefitMarkets::Products::ProductRateCache).to receive(:lookup_rate).and_return(100.0)
  end

  describe "methods" do
    let(:external_enrollment) { true }
    let(:enrollment_factory) {
      factory = Factories::FamilyEnrollmentCloneFactory.new
      factory.family = family
      factory.census_employee = ce
      factory.enrollment = family.enrollments.first
      factory
    }

    context "#clone_cobra_enrollment" do
      it "should successfully clone the enrollment" do
        expect(enrollment_factory.clone_cobra_enrollment.class).to eq(HbxEnrollment)
      end
    end
  end

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
      expect(cobra_enrollment.effective_on).to be >= cobra_enrollment.sponsored_benefit_package.benefit_application.start_on
      expect(cobra_enrollment.external_enrollment).to be_falsey
    end
  end

  context 'family under conversion employer' do
    let(:external_enrollment) { true }

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
      expect(cobra_enrollment.hbx_enrollment_members.first.coverage_start_on).to eq clone_enrollment.effective_on
    end

  end
end
