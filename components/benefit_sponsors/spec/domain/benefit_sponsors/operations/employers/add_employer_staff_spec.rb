# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BenefitSponsors::Operations::Employers::AddEmployerStaff, dbclean: :after_each do

  let(:person) {FactoryBot.create(:person)}
  let(:organization) { FactoryBot.create(:benefit_sponsors_organizations_general_organization, :with_site, "with_aca_shop_#{Settings.site.key}_employer_profile".to_sym)}
  let(:profile) { organization.employer_profile }
  let(:params) do
    {
      first_name: person.first_name,
      last_name: person.last_name,
      profile_id: profile.id.to_s,
      person_id: person.id.to_s,
      email: 'test@test.com',
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

    context 'existing staff with employer' do
      let!(:employer_staff_role) {FactoryBot.create(:benefit_sponsor_employer_staff_role, person: person, benefit_sponsor_employer_profile_id: profile.id)}

      it 'should fail if person is already associated as a staff with the employer' do
        result = subject.call(params)
        expect(result.failure).to eq({:message => 'Already staff role exists for the selected organization'})
      end
    end
  end

  context 'for success case' do

    let(:address) { {kind: 'test', address_1: 'test', city: 'test', state: 'DC', zip: '12345'} }
    let(:email) { { kind: 'primary', address: 'test@test.com' } }
    let(:coverage_record) { { is_applying_coverage: false, address: address, email: email }}

    it 'should return new staff entity' do
      result = subject.call(params.merge(coverage_record: coverage_record))
      expect(result.value![:message]).to eq "Successfully added employer staff role"
    end

    it 'should create staff role for person' do
      subject.call(params)
      person.reload
      expect(person.employer_staff_roles.first.benefit_sponsor_employer_profile_id).to eq profile.id
    end
  end
end
