# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Validators::PersonContract, type: :model, dbclean: :after_each do

  before :all do
    DatabaseCleaner.clean
  end

  it 'should be a container-ready operation' do
    expect(subject.respond_to?(:call)).to be_truthy
  end

  let(:person_params) do
    {first_name: 'ivl40', last_name: '41',
     dob: '1940-09-17', ssn: '345343243',
     gender: 'male', is_incarcerated: false,
     same_with_primary: true, indian_tribe_member: true, citizen_status: 'true',
     addresses: [kind: 'home', address_1: '123', address_2: '', address_3: '',
                 city: 'was', county: '', state: 'DC', location_state_code: nil,
                 full_text: nil, zip: '12321', country_name: '', tracking_version: 1,
                 modifier_id: nil], phones: [], emails: []}

  end

  context 'success case' do
    before do
      @result = subject.call(person_params)
    end

    it 'should return success' do
      expect(@result.success?).to be_truthy
    end

    it 'should not have any errors' do
      expect(@result.errors.empty?).to be_truthy
    end
  end

  context 'failure case' do

    context 'start on date is in the past' do
      before do
        @result = subject.call(person_params.except(:dob))
      end

      it 'should return failure' do
        expect(@result.failure?).to be_truthy
      end

      it 'should have any errors' do
        expect(@result.errors.empty?).to be_falsy
      end

      it 'should return error message as start date' do
        expect(@result.errors.messages.first.text).to eq('is missing')
      end
    end
  end
end
