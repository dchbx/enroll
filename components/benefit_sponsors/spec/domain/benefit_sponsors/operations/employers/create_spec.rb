# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BenefitSponsors::Operations::Employers::Create, dbclean: :after_each do

  describe 'Create' do

    let!(:site)  { FactoryBot.create(:benefit_sponsors_site, :with_owner_exempt_organization, :dc, :with_benefit_market) }
    let(:registration_params) do
      {
        profile_type: 'benefit_sponsor',
        staff_roles_attributes: {
          '0': { first_name: 'sandra',
                 last_name: 'mata',
                 dob: '12/01/1988',
                 email: 'test@test.com',
                 area_code: '347',
                 number: '8748937',
                 coverage_record:
                  {is_applying_coverage: 'true',
                   ssn: '139239231',
                   gender: 'Male',
                   hired_on: '2021-01-12',
                   address: {kind: 'home', address_1: 'home', address_2: "", city: 'dc', state: 'DC', zip: '22302'}, email: {kind: 'work', address: 'test@tes.com'}}}
        },
        organization: {legal_name: 'saregamapa', dba: "", fein: '438957897', entity_kind: 'c_corporation',
                       profile: {office_locations_attributes: {
                         '0': {address: {address_1: 'dc', kind: 'primary', address_2: 'dc', city: 'dc', state: 'DC', zip: '22302'},
                               phone: {kind: 'work', area_code: '387', number: '9873498'}}
                       }, contact_method: 'electronic_only'}},
        employer_id: ""
      }
    end


    subject do
      described_class.new.call(params)
    end

    context 'Failure' do
      context 'no params passed' do
        let(:params)  { {} }
        it 'should raise error if  no params are passed' do
          expect(subject).to be_failure
          expect(subject.failure).to eq({:text => "Invalid params", :error => {:profile_type => ["is missing"], :staff_roles_attributes => ["is missing"], :organization => ["is missing"]}})
        end
      end

      context 'params with invalid profile type passed' do
        let(:params)  { registration_params.merge(profile_type: 'test') }
        it 'should raise error if profile type is not passed' do
          expect(subject).to be_failure
          expect(subject.failure[:error][:profile_type]).to eq(["Invalid profile type"])
        end
      end
    end


    context 'success' do
      let(:person) {FactoryBot.create(:person)}

      context 'should create new organization' do
        let(:params)  { registration_params }

        it 'should create new employer profile and organization' do
          expect(subject).to be_success
          expect(BenefitSponsors::Organizations::Organization.all.count).to eq 2
          expect(BenefitSponsors::Organizations::Organization.employer_profiles.all.count).to eq 1
        end
      end

      context 'should create new employer staff role for person' do
        let(:staff_roles_attributes) do
          {
            '0': { person_id: person.id.to_s,
                   first_name: 'sandra',
                   last_name: 'mata',
                   dob: '12/01/1988',
                   email: 'test@test.com',
                   area_code: '347',
                   number: '8748937',
                   coverage_record:
                              {is_applying_coverage: 'true',
                               ssn: '139239231',
                               gender: 'Male',
                               hired_on: '2021-01-12',
                               address: {kind: 'home', address_1: 'home', address_2: "", city: 'dc', state: 'DC', zip: '22302'}, email: {kind: 'work', address: 'test@tes.com'}} }
          }
        end
        let(:params)  { registration_params.merge(person_id: person.id.to_s, staff_roles_attributes: staff_roles_attributes) }

        it 'should create new open struct object with keys' do
          expect(subject).to be_success
          expect(BenefitSponsors::Organizations::Organization.employer_profiles.all.count).to eq 1
          person.reload
          expect(person.employer_staff_roles.count).to eq 1
        end
      end
    end
  end
end
