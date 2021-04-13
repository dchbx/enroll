# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BenefitSponsors::Operations::BrokerAgencies::AddBrokerAgencyStaff, dbclean: :after_each do

  let(:person) {FactoryBot.create(:person)}
  let(:organization) { FactoryBot.create(:benefit_sponsors_organizations_general_organization, :with_site, :with_broker_agency_profile)}
  let(:profile) { organization.broker_agency_profile }
  let(:params) do
    {
      first_name: person.first_name,
      last_name: person.last_name,
      profile_id: profile.id.to_s,
      person_id: person.id.to_s,
      dob: TimeKeeper.date_of_record,
      coverage_record: {
        is_applying_coverage: false,
        address: {},
        email: {}
      }
    }
  end

  context 'for failure case' do
    it 'should fail if profile not found with given id' do
      result = subject.call(params.merge!({profile_id: 'test' }))
      expect(result.failure).to eq({:message => 'Profile not found'})
    end

    it 'should fail if person not found with given id' do
      result = subject.call(params.merge!({person_id: 'test' }))
      expect(result.failure).to eq({:message => ['Person not found']})
    end

    context 'existing staff with broker' do
      let!(:broker_agency_staff_role) {FactoryBot.create(:broker_agency_staff_role, person: person, benefit_sponsors_broker_agency_profile_id: profile.id)}

      it 'should fail if person is already associated as a staff with the broker agency' do
        result = subject.call(params)
        expect(result.failure).to eq({:message => 'Already staff role exists for the selected organization'})
      end
    end
  end

  context 'for success case' do
    it 'should return new staff entity' do
      result = subject.call(params)
      expect(result.value![:message]).to eq "Successfully added broker staff role"
    end

    it 'should create staff role for person' do
      subject.call(params)
      person.reload
      expect(person.broker_agency_staff_roles.first.benefit_sponsors_broker_agency_profile_id).to eq profile.id
    end
  end

  context 'already have a broker staff role in terminated state' do
    let!(:broker_staff_role) {FactoryBot.create(:broker_agency_staff_role, aasm_state: 'broker_agency_terminated', person: person, benefit_sponsors_broker_agency_profile_id: profile.id)}

    it 'should pass and move the staff from terminated to pending' do
      result = subject.call(params)
      expect(result.value![:message]).to eq 'Successfully moved broker staff role from terminated to pending'
      broker_staff_role.reload
      expect(broker_staff_role.aasm_state).to eq('broker_agency_pending')
    end
  end
end
