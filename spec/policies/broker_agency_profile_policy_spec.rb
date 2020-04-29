require 'rails_helper'

describe BrokerAgencyProfilePolicy, dbclean: :after_each do
  let(:user){FactoryBot.create(:user)}
  let(:person){FactoryBot.create(:person, user: user, broker_agency_staff_roles: [], broker_role: nil, hbx_staff_role: nil)}
  let(:broker_agency_profile) {FactoryBot.create(:broker_agency_profile)}
  let(:policy){BrokerAgencyProfilePolicy.new(user,broker_agency_profile)}
  context 'access to broker agency profile' do

    it 'hbx staff role' do
      FactoryBot.create(:hbx_staff_role, person: person)
      expect(policy.access_to_broker_agency_profile?).to be true
    end
    it 'no role' do
     expect(policy.access_to_broker_agency_profile?).not_to be true
    end

    it 'broker matches broker agency profile' do
      FactoryBot.create(:broker_role, person: person, broker_agency_profile: broker_agency_profile, aasm_state: 'active')
      expect(policy.access_to_broker_agency_profile?).to be true
    end

    it 'broker does not match broker agency profile' do
      FactoryBot.create(:broker_role, person: person, broker_agency_profile: FactoryBot.create(:broker_agency_profile), aasm_state: 'active')
      expect(policy.access_to_broker_agency_profile?).not_to be true
    end

    it 'broker matches broker agency profile but is applicant' do
      FactoryBot.create(:broker_role, person: person, broker_agency_profile: broker_agency_profile)
      expect(policy.access_to_broker_agency_profile?).not_to be true
    end

    it 'broker_agency_staff_roles can see broker agency profile' do
      FactoryBot.create(:broker_agency_staff_role, person: person, broker_agency_profile_id:broker_agency_profile.id,broker_agency_profile: broker_agency_profile, aasm_state: 'active')
      expect(policy.access_to_broker_agency_profile?).to be true
    end

    it 'broker_agency_staff_roles do not match broker agency profile' do
      FactoryBot.create(:broker_agency_staff_role, person: person, broker_agency_profile: FactoryBot.create(:broker_agency_profile), aasm_state: 'active')
      expect(policy.access_to_broker_agency_profile?).not_to be true
    end

    it 'broker_agency_staff_roles can find the  valid broker agency staff role' do
      FactoryBot.create(:broker_agency_staff_role, broker_agency_profile_id:broker_agency_profile.id, person: person, broker_agency_profile: broker_agency_profile, aasm_state: 'active')
      FactoryBot.create(:broker_agency_staff_role, broker_agency_profile_id:broker_agency_profile.id, person: person, broker_agency_profile: FactoryBot.create(:broker_agency_profile), aasm_state: 'active')
      expect(policy.access_to_broker_agency_profile?).to be true
    end

    it 'broker_agency_staff_roles invalid broker agency staff role due to aasm_state' do
      FactoryBot.create(:broker_agency_staff_role, person: person, broker_agency_profile: broker_agency_profile, aasm_state: 'is_applicant')
      FactoryBot.create(:broker_agency_staff_role, person: person, broker_agency_profile: FactoryBot.create(:broker_agency_profile), aasm_state: 'active')
      expect(policy.access_to_broker_agency_profile?).to be false
    end
  end
end
