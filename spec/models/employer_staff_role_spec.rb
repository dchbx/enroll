require 'rails_helper'
require_relative '../../components/benefit_sponsors/spec/concerns/observable_spec.rb'
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_market.rb"
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_application.rb"

describe EmployerStaffRole, dbclean: :after_each do
  include_context 'setup benefit market with market catalogs and product packages'
  include_context 'setup initial benefit application'

  it_behaves_like 'observable'

  let(:person) { FactoryBot.create(:person) }
  let(:employer_profile) { double(id: "valid_id") }

  describe ".new" do
    let(:valid_params) do
      {
        person: person,
        employer_profile_id: employer_profile.id
      }
    end

    context "with no arguments" do
      let(:params) {{}}

      it "should not save" do
        expect(EmployerStaffRole.new(**params).save).to be_falsey
      end
    end

     context "with valid params" do
      let(:params) { valid_params}

      it "should be valid" do
        expect(EmployerStaffRole.new(**params).valid?).to be_truthy
      end
     end

  end

  describe 'create_census_employee' do

    let!(:staff_role) {person.employer_staff_roles.create(benefit_sponsor_employer_profile_id: benefit_sponsorship.profile.id, aasm_state: "is_applicant")}

    context 'without coverage record' do
      it 'should approve poc' do
        expect(staff_role.approve!).to be_truthy
      end
    end

    context 'with coverage record and benefit packages' do
      let!(:coverage) do
        staff_role.coverage_record = CoverageRecord.new(encrypted_ssn: SymmetricEncryption.encrypt('123123453'), dob: TimeKeeper.date_of_record - 25.years, gender: 'male', hired_on: TimeKeeper.date_of_record - 1.years, is_applying_coverage: true)
        staff_role.coverage_record.email = FactoryBot.build(:email)
        staff_role.coverage_record.address = Address.new(kind: 'primary', address_1: '123 test', city: 'test', state: 'DC', zip: '20002')
      end

      before do
        staff_role.approve!
        @ce = CensusEmployee.where(first_name: person.first_name)
      end

      it 'should approve poc' do
        expect(staff_role.aasm_state).to eq 'is_active'
      end

      it 'should create census employee' do
        expect(@ce.present?).to be_truthy
      end

      it 'should create emmployee role' do
        expect(@ce.first.employee_role.present?).to be_truthy
      end
    end
  end
end
