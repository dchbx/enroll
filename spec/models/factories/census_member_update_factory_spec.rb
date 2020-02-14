# frozen_string_literal: true

require 'rails_helper'
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_market.rb"
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_application"

RSpec.describe Factories::CensusMemberUpdateFactory, :dbclean => :after_each do
  include_context 'setup benefit market with market catalogs and product packages'
  include_context 'setup renewal application'

  let(:family) { FactoryBot.create(:family, :with_primary_family_member_and_dependent) }
  let(:person) { family.primary_person }
  let(:family_members) { family.family_members.where(is_primary_applicant: false).to_a }
  let(:family_member) { family_members.first }
  let(:dependent_person) { family_members.first.person }
  let!(:census_dependent){FactoryBot.build(:census_dependent, first_name: dependent_person.first_name, last_name: dependent_person.last_name, dob: dependent_person.dob)}
  let!(:census_employee) do
    FactoryBot.create(:benefit_sponsors_census_employee,
                      :benefit_sponsorship => benefit_sponsorship,
                      :employer_profile => abc_profile,
                      :census_dependents => [census_dependent])
  end

  let(:employee_role) { FactoryBot.create(:benefit_sponsors_employee_role, person: person, census_employee_id: census_employee.id, benefit_sponsors_employer_profile_id: abc_profile.id)}
  let(:factory) {::Factories::CensusMemberUpdateFactory.new}

  context '.update_census_employee_records' do
    before do
      allow(person).to receive(:active_employee_roles).and_return([employee_role])
      person.assign_attributes(first_name: 'HAR', middle_name: 'SHA', last_name: 'E')
      factory.update_census_employee_records(person)
      census_employee.reload
    end

    it 'should update census employee record' do
      expect(census_employee.first_name).to eq 'HAR'
      expect(census_employee.middle_name).to eq 'SHA'
      expect(census_employee.last_name).to eq 'E'
    end
  end

  context 'should not update census employee records if no active employee roles' do
    it 'should not update census employee record' do
      expect(person.active_employee_roles).to eq []
      person.assign_attributes(first_name: 'HAR', middle_name: 'SHA', last_name: 'E')
      factory.update_census_employee_records(person)
      census_employee.reload
      expect(census_employee.first_name).not_to eq 'HAR'
      expect(census_employee.middle_name).not_to eq 'SHA'
      expect(census_employee.last_name).not_to eq 'E'
    end
  end

  describe '.update_census_dependent_records' do
    context 'updating family member details present on active enrollment' do
      let!(:hbx_enrollment) do
        FactoryBot.create(:hbx_enrollment, :with_enrollment_members, :with_product,
                          family: family,
                          aasm_state: 'coverage_enrolled',
                          effective_on: predecessor_application.start_on,
                          rating_area_id: predecessor_application.recorded_rating_area_id,
                          sponsored_benefit_id: predecessor_application.benefit_packages.first.health_sponsored_benefit.id,
                          sponsored_benefit_package_id: predecessor_application.benefit_packages.first.id,
                          benefit_sponsorship_id: predecessor_application.benefit_sponsorship.id,
                          employee_role_id: employee_role.id)
      end

      before do
        dependent_person.assign_attributes(first_name: 'VAR', last_name: 'DHAN')
        factory.update_census_dependent_records(dependent_person, family_member)
        census_employee.census_dependents.first.reload
      end

      it 'should update census dependent record' do
        expect(census_employee.census_dependents.first.first_name).to eq 'VAR'
        expect(census_employee.census_dependents.first.last_name).to eq 'DHAN'
      end
    end

    context 'updating family member details not present on active enrollment' do
      before do
        allow(person).to receive(:active_employee_roles).and_return([employee_role])
        dependent_person.assign_attributes(first_name: 'Test', last_name: 'Name')
        factory.update_census_dependent_records(dependent_person, family_member)
        census_employee.census_dependents.first.reload
      end

      it 'should update existing census dependent record' do
        expect(census_employee.census_dependents.first.first_name).to eq 'Test'
        expect(census_employee.census_dependents.first.last_name).to eq 'Name'
      end
    end

    context 'updating family member details present on expired/waived enrollment' do
      let!(:hbx_enrollment) do
        FactoryBot.create(:hbx_enrollment, :with_enrollment_members, :with_product,
                          family: family,
                          aasm_state: 'inactive',
                          effective_on: predecessor_application.start_on,
                          rating_area_id: predecessor_application.recorded_rating_area_id,
                          sponsored_benefit_id: predecessor_application.benefit_packages.first.health_sponsored_benefit.id,
                          sponsored_benefit_package_id: predecessor_application.benefit_packages.first.id,
                          benefit_sponsorship_id: predecessor_application.benefit_sponsorship.id,
                          employee_role_id: employee_role.id)
      end

      it 'should update census dependent record' do
        dependent_person.assign_attributes(first_name: 'VAR', last_name: 'DHAN')
        factory.update_census_dependent_records(dependent_person, family_member)
        census_employee.census_dependents.first.reload
        expect(census_employee.census_dependents.first.first_name).to eq 'VAR'
        expect(census_employee.census_dependents.first.last_name).to eq 'DHAN'
      end
    end

    context 'not to update family member details if no active employee roles' do
      it 'should not update existing census dependent record' do
        expect(person.active_employee_roles).to eq []
        dependent_person.assign_attributes(first_name: 'Test', last_name: 'Name')
        factory.update_census_dependent_records(dependent_person, family_member)
        census_employee.census_dependents.first.reload
        expect(census_employee.census_dependents.first.first_name).not_to eq 'Test'
        expect(census_employee.census_dependents.first.last_name).not_to eq 'Name'
      end
    end
  end

  describe '.update_census_dependent_relationship' do
    before do
      allow(person).to receive(:active_employee_roles).and_return([employee_role])
    end

    context 'should update census dependent relationship if it is valid employee relationship kind' do
      it 'should update census dependent' do
        expect(census_employee.census_dependents.first.employee_relationship).to eq 'spouse'
        family_member.update_relationship('domestic_partner')
        expect(census_employee.census_dependents.first.reload.employee_relationship).to eq 'domestic_partner'
      end
    end

    context 'should not update census dependent relationship if it is invalid employee relationship kind' do
      let(:relationship) { 'sibling' }

      it 'should not update census dependent' do
        expect(census_employee.census_dependents.first.employee_relationship).to eq 'spouse'
        family_member.update_relationship('sibling')
        expect(census_employee.census_dependents.first.reload.employee_relationship).to eq 'spouse'
      end
    end
  end

  describe '.create_census_dependent' do
    let(:dob) { '2007-06-09' }
    let(:person_properties) do
      {
        :first_name => 'aaa',
        :last_name => 'bbb',
        :middle_name => 'ccc',
        :ssn => '123456778',
        :no_ssn => '',
        :gender => 'male',
        :dob => dob
      }
    end

    subject { Forms::FamilyMember.new(person_properties.merge({:family_id => family.id, :relationship => relationship })) }

    before do
      allow(person).to receive(:active_employee_roles).and_return([employee_role])
    end

    context 'when a family member is added with valid employee relationship kind' do
      let(:relationship) { 'child' }

      it 'should create new census dependent' do
        expect(census_employee.census_dependents.count).to eq 1
        subject.save
        expect(census_employee.reload.census_dependents.count).to eq 2
      end
    end

    context 'when a family member is added with invalid employee relationship kind' do
      let(:relationship) { 'sibling' }

      it 'should not create new census dependent' do
        expect(census_employee.census_dependents.count).to eq 1
        subject.save
        expect(census_employee.reload.census_dependents.count).to eq 1
      end
    end
  end
end
