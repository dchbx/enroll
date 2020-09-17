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
         addresses: [kind: 'home', address_1: '123', address_2: '', address_3: '',
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

    # context 'for success case if person already exists in db' do
    #   let!(:person) {FactoryBot.create(:person)}
    #   let(:person_params) do
    #     {first_name: person.first_name, last_name: person.last_name,
    #      dob: person.dob, no_ssn: '1',
    #      gender: 'male', is_incarcerated: false,
    #      person_hbx_id: person.hbx_id,
    #      same_with_primary: true, indian_tribe_member: true, citizen_status: 'true',
    #      addresses: [kind: 'home', address_1: '123', address_2: '', address_3: '',
    #                  city: 'was', county: '', state: 'DC', location_state_code: nil,
    #                  full_text: nil, zip: '12321', country_name: '', tracking_version: 1,
    #                  modifier_id: nil], phones: [], emails: []}

    #   end

    #   context 'valid params' do
    #     before :each do
    #       @result = subject.call(params: person_params)
    #     end

    #     it 'should return success' do
    #       expect(@result).to be_a(Dry::Monads::Result::Success)
    #     end
    #   end
    # end

    context 'for failed case' do

      let(:person_params) do
        {first_name: 'ivl40', last_name: '41',
         dob: '1940-09-17', ssn: '345343243',
         gender: 'male', is_incarcerated: false,
         person_hbx_id: '23232323',
         same_with_primary: true, indian_tribe_member: true, citizen_status: 'true',
         addresses: [kind: 'home', address_1: '123', address_2: '', address_3: '',
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
    #
    # context 'update person' do
    # let(:person) {FactoryBot.create(:person)}

    #   let(:person_params) do
    #     {first_name: person.first_name, last_name: person.last_name,
    #      dob: person.dob, ssn: person.ssn,
    #      gender: 'male', is_incarcerated: false,
    #      person_hbx_id: person.hbx_id,
    #      same_with_primary: true, indian_tribe_member: true, citizen_status: 'true',
    #      addresses: [kind: 'home', address_1: '123', address_2: '', address_3: '',
    #                  city: 'was', county: '', state: 'DC', location_state_code: nil,
    #                  full_text: nil, zip: '12321', country_name: '', tracking_version: 1,
    #                  modifier_id: nil], phones: [], emails: []}
    #
    #   end
    #
    #   context 'valid params' do
    #     it 'should return success' do
    #       result = subject.call(params: person_params)
    #       expect(result.success).to be_truthy
    #     end
    #   end
    # end
  end
end
