# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BenefitSponsors::Operations::Employers::EmployerStaffRoles::Create, dbclean: :after_each do

  let(:employer_org) { FactoryBot.create(:benefit_sponsors_organizations_general_organization, :with_site, :with_aca_shop_dc_employer_profile)}
  let(:ga_organization) { FactoryBot.create(:benefit_sponsors_organizations_general_organization, :with_site, :with_general_agency_profile)}

  let(:employer_profile) { employer_org.employer_profile }
  let(:ga_profile) { ga_organization.general_agency_profile }

  let(:params) { {first_name: 'test', coverage_record: {is_applying_coverage: false, address: {}, email: {}}}}


  context 'failure case' do
    it 'should fail if profile not found with given id' do
      result = subject.call(params: params, profile: nil)
      expect(result.failure).to eq({:message => 'Invalid profile'})
    end

    it 'should fail if profile is not a  employer profile' do
      result = subject.call(params: params, profile: ga_profile)
      expect(result.failure).to eq({:message => 'Invalid profile'})
    end
  end

  context 'Success case' do
    it 'should return employer staff entity' do
      result = subject.call(params: params, profile: employer_profile)
      expect(result.value!).to be_a BenefitSponsors::Entities::Employers::EmployerStaffRoles::EmployerStaffRole
    end
  end
end
