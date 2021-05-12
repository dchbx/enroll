# frozen_string_literal: true

require 'rails_helper'
RSpec.describe ::Operations::People::CompareForDataChange, dbclean: :after_each do

  describe 'valid params' do
    let!(:person) do
      per = FactoryBot.create(:person, :with_consumer_role, hbx_id: '13cce9fe14b04209b2443330900108d8',
                              dob: (Date.today - 1.years).strftime('%d/%m/%Y'), first_name: 'childfirst',
                              last_name: 'childlast', gender: 'male')
      per.addresses = [FactoryBot.build(:address, :mailing_kind, address_1: '1 Awesome Street NE', address_2: '#1', state: 'DC')]
      per.addresses << FactoryBot.build(:address, address_1: '2 Awesome Street NE', address_2: '#2', state: 'DC')
      per.emails = [FactoryBot.build(:email, kind: 'work'), FactoryBot.build(:email, kind: 'home')]
      per.phones = [FactoryBot.build(:phone, kind: 'work'), FactoryBot.build(:phone, kind: 'home')]
      per.save!
      per
    end

    context 'for incoming payload and existing attributes are different' do
      let(:person_params) do
        {:hbx_id=>'13cce9fe14b04209b2443330900108d8',
         :ssn=>person.ssn,
         :dob=>(Date.today - 1.years),
         first_name: 'childfirst10',
         last_name: 'childlast',
         gender: 'male'}
      end

      before do
        @result = subject.call(params: {attributes_hash: person_params, person: person})
      end

      it 'should return a success object' do
        expect(@result).to be_a(Dry::Monads::Result::Success)
      end

      it 'should return success with a message' do
        expect(@result.success).to eq('Information has changed')
      end
    end

    context 'for incoming payload and existing attributes are same' do
      let(:person_params) do
        {:hbx_id=>'13cce9fe14b04209b2443330900108d8',
         :ssn=>person.ssn,
         :dob=>(Date.today - 1.years),
         first_name: 'childfirst',
         last_name: 'childlast',
         gender: 'male'}
      end

      context 'matching hbx_id' do
        before do
          @result = subject.call(params: {attributes_hash: person_params, person: person})
        end

        it 'should return a failure object' do
          expect(@result).to be_a(Dry::Monads::Result::Failure)
        end

        it 'should return failure with a message' do
          expect(@result.failure).to eq('No information is changed')
        end
      end

      context 'different hbx_id' do
        before do
          person_params.merge!({hbx_id: '11aaa1aa11a11111a1111111111111a1'})
          @result = subject.call(params: {attributes_hash: person_params, person: person})
        end

        it 'should return a failure object' do
          expect(@result).to be_a(Dry::Monads::Result::Failure)
        end

        it 'should return failure with a message' do
          expect(@result.failure).to eq('No information is changed')
        end
      end
    end

    context 'for incoming payload and existing attributes are same but attributes order changed' do
      let(:person_params) do
        {:hbx_id=>'13cce9fe14b04209b2443330900108d8',
         :ssn=>person.ssn,
         :dob=>(Date.today - 1.years),
         first_name: 'childfirst',
         last_name: 'childlast',
         gender: 'male',
         :addresses=>[person.mailing_address.serializable_hash.symbolize_keys.except(:_id, :created_at, :updated_at, :tracking_version, :full_text, :location_state_code, :modifier_id, :primary),
                      person.home_address.serializable_hash.symbolize_keys.except(:_id, :created_at, :updated_at, :tracking_version, :full_text, :location_state_code, :modifier_id, :primary)]}
      end

      before :each do
        @result = subject.call(params: {attributes_hash: person_params, person: person})
      end

      it 'should return a failure object' do
        expect(@result).to be_a(Dry::Monads::Result::Failure)
      end

      it 'should return failure with a message' do
        expect(@result.failure).to eq('No information is changed')
      end
    end
  end

  describe 'invalid params' do
    before do
      @result = subject.call(params: {attributes_hash: 'person_params', person: 'person'})
    end

    it 'should return a failure object' do
      expect(@result).to be_a(Dry::Monads::Result::Failure)
    end

    it 'should return failure with message' do
      expect(@result.failure).to eq('Bad person object')
    end
  end
end

def compare(person_db_hash)
  sanitized_person_hash = person_db_hash.inject({}) do |db_hash, element_hash|
    db_hash[element_hash[0]] = if [:addresses, :emails, :phones].include?(element_hash[0])
                                 fetch_array_of_attrs_for_embeded_objects(element_hash[1])
                               else
                                 element_hash[1]
                               end
    db_hash
  end
end

def fetch_array_of_attrs_for_embeded_objects(data)
  new_arr = []
  data.each do |special_hash|
    new_arr << special_hash.symbolize_keys.except(:_id, :created_at, :updated_at, :tracking_version, :full_text, :location_state_code, :modifier_id, :primary)
  end
  new_arr
end
