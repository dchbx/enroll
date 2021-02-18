# frozen_string_literal: true

require 'rails_helper'
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_market.rb"
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_application.rb"

RSpec.describe Operations::HbxEnrollments::Build, :type => :model, dbclean: :around_each do
  include_context 'setup benefit market with market catalogs and product packages'
  include_context 'setup initial benefit application'

  let(:current_effective_date) { TimeKeeper.date_of_record.beginning_of_month }
  let(:effective_on) { current_effective_date }
  let(:hired_on) { TimeKeeper.date_of_record - 3.months }
  let(:employee_created_at) { hired_on }
  let(:employee_updated_at) { employee_created_at }
  let(:person) {FactoryBot.create(:person, first_name: 'John', last_name: 'Smith', dob: '1966-10-10'.to_date, ssn: '123456789')}
  let!(:sponsored_benefit) {benefit_sponsorship.benefit_applications.first.benefit_packages.first.health_sponsored_benefit}
  let!(:update_sponsored_benefit) {sponsored_benefit.update_attributes(product_package_kind: :single_product)}
  let(:aasm_state) { :active }
  let(:census_employee) do
    create(:census_employee,
           :with_active_assignment,
           benefit_sponsorship: benefit_sponsorship,
           benefit_sponsors_employer_profile_id: benefit_sponsorship.profile.id,
           benefit_group: current_benefit_package,
           hired_on: hired_on,
           created_at: employee_created_at,
           updated_at: employee_updated_at)
  end
  let!(:family) do
    person = FactoryBot.create(:person, last_name: census_employee.last_name, first_name: census_employee.first_name)
    employee_role = FactoryBot.create(:employee_role, person: person, census_employee: census_employee, benefit_sponsors_employer_profile_id: abc_profile.id)
    census_employee.update_attributes({employee_role: employee_role})
    Family.find_or_build_from_employee_role(employee_role)
  end
  let!(:employee_role){census_employee.employee_role}
  let(:enrollment_kind) { 'open_enrollment' }
  let(:special_enrollment_period_id) { nil }
  let(:covered_individuals) { family.family_members }
  let(:person) { family.primary_applicant.person }
  let!(:enrollment) do
    FactoryBot.create(:hbx_enrollment, :with_enrollment_members,
                      enrollment_members: covered_individuals,
                      household: family.latest_household,
                      coverage_kind: 'health',
                      family: family,
                      effective_on: effective_on,
                      enrollment_kind: enrollment_kind,
                      kind: 'employer_sponsored',
                      benefit_sponsorship_id: benefit_sponsorship.id,
                      sponsored_benefit_package_id: current_benefit_package.id,
                      sponsored_benefit_id: current_benefit_package.sponsored_benefits[0].id,
                      employee_role_id: employee_role.id,
                      product: sponsored_benefit.reference_product,
                      rating_area_id: BSON::ObjectId.new,
                      benefit_group_assignment_id: census_employee.active_benefit_group_assignment.id)
  end

  before do
    census_employee.terminate_employment(effective_on + 1.days)
    enrollment.reload
    census_employee.reload
  end

  context 'success' do
    let(:current_year) {current_effective_date.year}
    let(:end_of_year) {Date.new(current_year, 12, 31)}

    before do
      allow(TimeKeeper).to receive(:date_of_record).and_return(Date.new(current_year, 10, 15))
    end

    context 'valid hbx_enrollment' do
      before do
        enrollment_params = enrollment.serializable_hash.deep_symbolize_keys
        @new_enrollment = subject.call(enrollment_params).success
      end

      it 'should return a success with a HbxEnrollment entity' do
        expect(@new_enrollment).to be_a(::Entities::HbxEnrollments::HbxEnrollment)
      end

      it 'should return a HbxEnrollment with same aasm_state' do
        expect(@new_enrollment.aasm_state).to eq('coverage_termination_pending')
      end

      it 'should return a HbxEnrollment with same effective_on' do
        expect(@new_enrollment.effective_on).to eq(enrollment.effective_on)
      end
    end
  end

  context 'failure' do
    context 'no params' do
      before do
        @result = subject.call({})
      end

      it 'should return a failure with set of missing keys' do
        expect(@result.failure.to_h.keys).to eq([:kind, :enrollment_kind, :coverage_kind, :effective_on])
      end
    end
  end
end
