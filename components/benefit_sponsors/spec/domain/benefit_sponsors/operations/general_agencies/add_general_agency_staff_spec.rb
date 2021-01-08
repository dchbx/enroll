# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BenefitSponsors::Operations::GeneralAgencies::AddGeneralAgencyStaff, dbclean: :after_each do

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
      dob: TimeKeeper.date_of_record,
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
      expect(result.failure).to eq({:message => ["Person not found"]})
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
    it 'should return new ga staff entity' do
      result = subject.call(params)
      expect(result.value![:message]).to eq 'Successfully added general agency staff role'
    end
  end
end
