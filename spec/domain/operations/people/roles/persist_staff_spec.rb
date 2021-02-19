# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Operations::People::Roles::PersistStaff, type: :model, dbclean: :after_each do
  before :all do
    DatabaseCleaner.clean
  end

  it 'should be a container-ready operation' do
    expect(subject.respond_to?(:call)).to be_truthy
  end

  let(:person) {FactoryBot.create(:person)}
  let(:organization) { FactoryBot.create(:benefit_sponsors_organizations_general_organization, :with_site, "with_aca_shop_#{Settings.site.key}_employer_profile".to_sym)}
  let(:profile) { organization.employer_profile }
  let(:params) do
    {
      first_name: person.first_name,
      last_name: person.last_name,
      profile_id: profile.id.to_s,
      person_id: person.id.to_s,
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
  end

  context 'for success case' do
    it 'should return new staff entity' do
      result = subject.call(params)
      expect(result.value![:message]).to eq "Successfully added employer staff role"
    end
  end

  describe 'create Broker staff' do
    let(:person) {FactoryBot.create(:person)}
    let(:organization) { FactoryBot.create(:benefit_sponsors_organizations_general_organization, :with_site, :with_broker_agency_profile)}
    let(:profile) { organization.broker_agency_profile }
    let(:params) do
      {
        first_name: person.first_name,
        last_name: person.last_name,
        profile_id: profile.id.to_s,
        person_id: person.id.to_s,
        coverage_record: {
          is_applying_coverage: false,
          address: {},
          email: {}
        }
      }
    end

    context 'failure case' do
      it 'should fail if profile not found with given id' do
        result = subject.call(params.merge!({profile_id: 'test' }))
        expect(result.failure).to eq({:message => 'Profile not found'})
      end

      it 'should fail if person not found with given id' do
        result = subject.call(params.merge!({person_id: 'test' }))
        expect(result.failure).to eq({:message => 'Person not found'})
      end
    end

    context 'already have a broker staff role in pending or applicant state' do
      let!(:broker_staff_role) {FactoryBot.create(:broker_agency_staff_role, person: person, benefit_sponsors_broker_agency_profile_id: profile.id)}

      it 'should fail if person already has a staff role associated to same agency' do
        result = subject.call(params)
        expect(result.failure).to eq({:message => 'Already staff role exists for the selected organization'})
      end
    end

    context 'already have a broker staff role in terminated state' do
      let!(:broker_staff_role) {FactoryBot.create(:broker_agency_staff_role, aasm_state: 'broker_agency_terminated', person: person, benefit_sponsors_broker_agency_profile_id: profile.id)}

      it 'should pass and move the staff from terminated to pending' do
        result = subject.call(params)
        expect(result.value![:message]).to eq 'Successfully moved staff role from terminated to pending'
        broker_staff_role.reload
        expect(broker_staff_role.aasm_state).to eq('broker_agency_pending')
      end
    end

    context 'for success case' do
      it 'should return new staff entity' do
        result = subject.call(params)
        expect(result.value![:message]).to eq 'Successfully added broker staff role'
      end
    end
  end

  describe 'create GA staff' do
    let(:current_person) {FactoryBot.create(:person)}
    let(:primary_staff_person) {FactoryBot.create(:person)}
    let(:organization) { FactoryBot.create(:benefit_sponsors_organizations_general_organization, :with_site, :with_general_agency_profile)}
    let(:profile) { organization.general_agency_profile }
    let!(:ga_staff_role) {FactoryBot.create(:general_agency_staff_role, is_primary: true, person: primary_staff_person, benefit_sponsors_general_agency_profile_id: profile.id)}
    let(:params) do
      {
        first_name: current_person.first_name,
        last_name: current_person.last_name,
        profile_id: profile.id.to_s,
        person_id: current_person.id.to_s,
        coverage_record: {
          is_applying_coverage: false,
          address: {},
          email: {}
        }
      }
    end

    context 'failure case' do
      it 'should fail if profile not found with given id' do
        result = subject.call(params.merge!({profile_id: 'test' }))
        expect(result.failure).to eq({:message => 'Profile not found'})
      end

      it 'should fail if person not found with given id' do
        result = subject.call(params.merge!({person_id: 'test' }))
        expect(result.failure).to eq({:message => 'Person not found'})
      end
    end

    context 'already have a ga staff role in pending or applicant state' do
      let!(:ga_staff_role) {FactoryBot.create(:general_agency_staff_role, is_primary: true, person: current_person, benefit_sponsors_general_agency_profile_id: profile.id)}

      it 'should fail if person already has a staff role associated to same agency' do
        result = subject.call(params)
        expect(result.failure).to eq({:message => 'Already staff role exists for the selected organization'})
      end
    end

    context 'already have a ga staff role in terminated state' do
      let!(:ga_staff_role) {FactoryBot.create(:general_agency_staff_role, aasm_state: 'general_agency_terminated', person: current_person, benefit_sponsors_general_agency_profile_id: profile.id)}

      it 'should pass and move the staff from terminated to pending' do
        result = subject.call(params)
        expect(result.value![:message]).to eq 'Successfully moved staff role from terminated to pending'
        ga_staff_role.reload
        expect(ga_staff_role.aasm_state).to eq('general_agency_pending')
      end
    end

    context 'for success case' do
      it 'should return new staff entity' do
        result = subject.call(params)
        expect(result.value![:message]).to eq 'Successfully added general agency staff role'
      end
    end
  end
end
