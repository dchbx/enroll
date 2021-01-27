# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BenefitSponsors::Operations::Profiles::Sanitize, dbclean: :after_each do


  describe 'sanitize request params' do

    subject do
      described_class.new.call(params)
    end

    let(:person) { FactoryBot.create(:person) }

    let(:params) do
      {
        person_id: person.id.to_s,
        profile_type: 'benefit_sponsor',
        staff_roles_attributes: {
          '0' => { person_id: person.id.to_s,
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
                    address: { kind: 'home', address_1: 'home', address_2: "", city: 'dc', state: 'DC', zip: '22302' }, email: { kind: 'work', address: 'test@test.com' }}}
        },
        organization: {
          legal_name: 'saregamapa', dba: "", fein: '438957897', entity_kind: 'c_corporation',
          profile: {
            office_locations_attributes: {
              '0' => {
                address: { address_1: 'dc', kind: 'primary', address_2: 'dc', city: 'dc', state: 'DC', zip: '22302' },
                phone: { kind: 'work', area_code: '387', number: '9873498'}
              }
            },
            contact_method: 'electronic_only'
          }
        },
        employer_id: ""
      }
    end

    it 'should sanitize request params of profile registration' do
      expect(subject).to be_success
    end

    it 'should sanitize and return office locations as array' do
      expect(subject.value![:organization][:profile][:office_locations]).to be_a Array
    end
  end
end
