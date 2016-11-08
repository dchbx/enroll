require 'rails_helper'

describe BrokerAgencyProfilePolicy do
  let(:user){FactoryGirl.create(:user)}
  let(:person){FactoryGirl.create(:person, user: user, broker_agency_staff_roles: [], broker_role: nil, hbx_staff_role: nil)}
  let(:broker_agency_profile) {FactoryGirl.create(:broker_agency_profile)}
  let(:policy){BrokerAgencyProfilePolicy.new(user,broker_agency_profile)}
  context 'access to broker agency profile' do

    it 'hbx staff role' do
      FactoryGirl.create(:hbx_staff_role, person: person)
      expect(policy.access_to_broker_agency_profile?).to be true
    end
    it 'no role' do
     expect(policy.access_to_broker_agency_profile?).not_to be true
    end

    it 'broker matches broker agency profile' do
      FactoryGirl.create(:broker_role, person: person, broker_agency_profile: broker_agency_profile, aasm_state: 'active')
      expect(policy.access_to_broker_agency_profile?).to be true
    end

    it 'broker does not match broker agency profile' do
      FactoryGirl.create(:broker_role, person: person, broker_agency_profile: FactoryGirl.create(:broker_agency_profile), aasm_state: 'active')
      expect(policy.access_to_broker_agency_profile?).not_to be true
    end

    it 'broker matches broker agency profile but is applicant' do
      FactoryGirl.create(:broker_role, person: person, broker_agency_profile: broker_agency_profile)
      expect(policy.access_to_broker_agency_profile?).not_to be true
    end

    it 'broker_agency_staff_roles can see broker agency profile' do
      FactoryGirl.create(:broker_agency_staff_role, person: person, broker_agency_profile: broker_agency_profile, aasm_state: 'active')
      expect(policy.access_to_broker_agency_profile?).to be true
    end

    it 'broker_agency_staff_roles do not match broker agency profile' do
      FactoryGirl.create(:broker_agency_staff_role, person: person, broker_agency_profile: FactoryGirl.create(:broker_agency_profile), aasm_state: 'active')
      expect(policy.access_to_broker_agency_profile?).not_to be true
    end

    it 'broker_agency_staff_roles can find the  valid broker agency staff role' do
      FactoryGirl.create(:broker_agency_staff_role, person: person, broker_agency_profile: broker_agency_profile, aasm_state: 'active')
      FactoryGirl.create(:broker_agency_staff_role, person: person, broker_agency_profile: FactoryGirl.create(:broker_agency_profile), aasm_state: 'active')
      expect(policy.access_to_broker_agency_profile?).to be true
    end

    it 'broker_agency_staff_roles invalid broker agency staff role due to aasm_state' do
      FactoryGirl.create(:broker_agency_staff_role, person: person, broker_agency_profile: broker_agency_profile, aasm_state: 'is_applicant')
      FactoryGirl.create(:broker_agency_staff_role, person: person, broker_agency_profile: FactoryGirl.create(:broker_agency_profile), aasm_state: 'active')
      expect(policy.access_to_broker_agency_profile?).to be false
    end
  end
end
