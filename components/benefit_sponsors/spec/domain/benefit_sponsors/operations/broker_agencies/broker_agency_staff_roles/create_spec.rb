# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BenefitSponsors::Operations::BrokerAgencies::BrokerAgencyStaffRoles::Create, dbclean: :after_each do

  let(:ba_organization) { FactoryBot.create(:benefit_sponsors_organizations_general_organization, :with_site, :with_broker_agency_profile)}
  let(:ga_organization) { FactoryBot.create(:benefit_sponsors_organizations_general_organization, :with_site, :with_general_agency_profile)}

  let(:ba_profile) { ba_organization.broker_agency_profile }
  let(:ga_profile) { ga_organization.general_agency_profile }


  context 'failure case' do
    it 'should fail if profile not found with given id' do
      result = subject.call(profile: nil)
      expect(result.failure).to eq({:message => 'Invalid profile'})
    end

    it 'should fail if profile is not a broker agency profile' do
      result = subject.call(profile: ga_profile)
      expect(result.failure).to eq({:message => 'Invalid profile'})
    end
  end

  context 'Success case' do
    it 'should return broker agency staff entity' do
      result = subject.call(profile: ba_profile)
      expect(result.value!).to be_a BenefitSponsors::Entities::BrokerAgencies::BrokerAgencyStaffRoles::BrokerAgencyStaffRole
    end
  end
end
