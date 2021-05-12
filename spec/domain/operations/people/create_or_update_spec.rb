# frozen_string_literal: true

require 'rails_helper'
RSpec.describe Operations::People::CreateOrUpdate, type: :model, dbclean: :after_each do

  before :all do
    DatabaseCleaner.clean
  end

  context 'create person' do
    it 'should be a container-ready operation' do
      expect(subject.respond_to?(:call)).to be_truthy
    end

    context 'for success case' do

      let(:person_params) do
        {first_name: 'ivl40', last_name: '41',
         dob: '1940-09-17', ssn: '345343243',
         gender: 'male', is_incarcerated: false,
         person_hbx_id: '23232323',
         same_with_primary: true, indian_tribe_member: true, citizen_status: 'true',
         addresses: [kind: 'home', address_1: '123 NE', address_2: '', address_3: '',
                     city: 'was', county: '', state: 'DC', location_state_code: nil,
                     full_text: nil, zip: '12321', country_name: '', tracking_version: 1,
                     modifier_id: nil], phones: [], emails: []}

      end

      context 'valid params' do
        before :each do
          @result = subject.call(params: person_params)
        end

        it 'should return success' do
          expect(@result).to be_a(Dry::Monads::Result::Success)
        end
      end
    end

    context 'for success case if person already exists in db and updating with same details' do
      let!(:person) {FactoryBot.create(:person)}
      let!(:person_params) do
        {first_name: person.first_name, last_name: person.last_name,
         dob: person.dob, no_ssn: '1',
         gender: 'male', is_incarcerated: false,
         person_hbx_id: person.hbx_id,
         same_with_primary: true, indian_tribe_member: true, citizen_status: 'true',
         addresses: person.serializable_hash.deep_symbolize_keys[:addresses],
         phones: person.serializable_hash.deep_symbolize_keys[:phones], emails: person.serializable_hash.deep_symbolize_keys[:emails]}
      end

      before :each do
        @result = subject.call(params: person_params)
      end

      context 'valid params' do
        it 'should return success' do
          expect(@result).to be_a(Dry::Monads::Result::Success)
        end
      end
    end

    context 'for failed case' do
      let(:person_params) do
        {first_name: 'ivl40', last_name: '41',
         dob: '1940-09-17', ssn: '345343243',
         gender: 'male', is_incarcerated: false,
         person_hbx_id: '23232323',
         same_with_primary: true, indian_tribe_member: true, citizen_status: 'true',
         addresses: [kind: 'home', address_1: '123 NE', address_2: '', address_3: '',
                     city: 'was', county: '', state: 'DC', location_state_code: nil,
                     full_text: nil, zip: '12321', country_name: '', tracking_version: 1,
                     modifier_id: nil], phones: [], emails: []}

      end

      context 'valid params' do
        before :each do
          @result = subject.call(params: person_params.except(:dob))
        end

        it 'should return failure' do
          expect(@result).to be_a(Dry::Monads::Result::Failure)
        end
      end
    end
  end

  context 'update person' do
    let!(:person) {FactoryBot.create(:person)}
    let!(:person_params) do
      {first_name: person.first_name, last_name: person.last_name,
       dob: person.dob, no_ssn: '1',
       gender: 'female', is_incarcerated: false,
       person_hbx_id: person.hbx_id,
       same_with_primary: true, indian_tribe_member: true, citizen_status: 'true',
       addresses: person.serializable_hash.deep_symbolize_keys[:addresses],
       phones: person.serializable_hash.deep_symbolize_keys[:phones], emails: person.serializable_hash.deep_symbolize_keys[:emails]}
    end

    context 'matching hbx_id' do
      before :each do
        @result = subject.call(params: person_params)
      end

      context 'valid params' do
        it 'should return success' do
          expect(@result).to be_a(Dry::Monads::Result::Success)
        end

        it 'should update gender' do
          expect(person.reload.gender).to eq 'female'
        end
      end
    end

    context 'different hbx_id' do
      before :each do
        person_params.merge!({person_hbx_id: '100asd29'})
        @result = subject.call(params: person_params)
      end

      context 'valid params' do
        it 'should return success' do
          expect(@result).to be_a(Dry::Monads::Result::Success)
        end

        it 'should update gender' do
          expect(person.reload.gender).to eq 'female'
        end
      end
    end
  end

  context "update person with applicant's updates" do
    let!(:person10) do
      per = FactoryBot.create(:person, :with_consumer_role, :with_active_consumer_role, is_incarcerated: false)
      per.addresses = [FactoryBot.build(:address, :mailing_kind, address_1: '1 Awesome Street NE', address_2: '#1', state: 'DC')]
      per.addresses << FactoryBot.build(:address, address_1: '2 Awesome Street NE', address_2: '#2', state: 'DC')
      per.emails = [FactoryBot.build(:email, kind: 'work', address: 'test@test.com'), FactoryBot.build(:email, kind: 'home', address: 'test10@test.com')]
      per.phones = [FactoryBot.build(:phone, kind: 'work'), FactoryBot.build(:phone, kind: 'home')]
      per.save!
      per
    end
    let!(:family10) { FactoryBot.create(:family, :with_primary_family_member, person: person10) }
    let!(:application10) { FactoryBot.create(:financial_assistance_application, family_id: family10.id) }
    let!(:applicant10) do
      FactoryBot.create(:financial_assistance_applicant,
                        :with_work_phone,
                        :with_work_email,
                        :with_home_address,
                        family_member_id: family10.primary_applicant.id,
                        application: application10,
                        gender: person10.gender,
                        is_incarcerated: person10.is_incarcerated,
                        ssn: person10.ssn,
                        dob: person10.dob,
                        first_name: person10.first_name,
                        last_name: person10.last_name,
                        is_primary_applicant: true,
                        person_hbx_id: person10.hbx_id)
    end

    before do
      @result = subject.call(params: applicant10.attributes_for_export)
    end

    it 'should return success object' do
      expect(@result).to be_a(Dry::Monads::Result::Success)
    end

    it 'should update work email address' do
      expect(@result.success.work_email.address).to eq(applicant10.emails.first.address)
    end
  end
end
