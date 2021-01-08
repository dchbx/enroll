# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BenefitSponsors::Operations::GeneralAgencies::GeneralAgencyStaffRoles::Create, dbclean: :after_each do

  let(:ba_organization) { FactoryBot.create(:benefit_sponsors_organizations_general_organization, :with_site, :with_broker_agency_profile)}
  let(:ga_organization) { FactoryBot.create(:benefit_sponsors_organizations_general_organization, :with_site, :with_general_agency_profile)}

  let(:ba_profile) { ba_organization.broker_agency_profile }
  let(:ga_profile) { ga_organization.general_agency_profile }


  context 'failure case' do
    it 'should fail if profile not found with given id' do
      result = subject.call(profile: nil)
      expect(result.failure).to eq({:message => 'Invalid profile'})
    end

    it 'should fail if profile is not a general agency profile' do
      result = subject.call(profile: ba_profile)
      expect(result.failure).to eq({:message => 'Invalid profile'})
    end

    it 'should fail if profile has no primary ga' do
      result = subject.call(profile: ga_profile)
      expect(result.failure).to eq({:message => 'Unable to build general agency staff role'})
    end
  end

  context 'Success case' do
    let!(:person) {FactoryBot.create(:person)}
    let!(:general_agency_staff_role) { FactoryBot.create(:general_agency_staff_role, npn: '123456', benefit_sponsors_general_agency_profile_id: ga_profile.id, person: person)}
    it 'should return general agency staff entity' do
      allow(ga_profile).to receive(:general_agency_primary_staff).and_return(general_agency_staff_role)
      result = subject.call(profile: ga_profile)
      expect(result.value!).to be_a BenefitSponsors::Entities::GeneralAgencies::GeneralAgencyStaffRoles::GeneralAgencyStaffRole
    end
  end
end
