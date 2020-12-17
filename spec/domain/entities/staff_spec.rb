# frozen_string_literal: true

require 'rails_helper'
RSpec.describe ::Entities::Staff, dbclean: :after_each do
  before :all do
    DatabaseCleaner.clean
  end

  describe 'initialize instance' do
    let(:params) do
      {
        person_id: 'id',
        first_name: 'jhon',
        last_name: 'doe'
      }
    end

    context 'with valid params' do
      it 'should initialize staff instance' do
        expect(::Entities::Staff.new(params)).to be_a ::Entities::Staff
      end
    end

    context 'with valid optional params' do
      it 'should initialize with optional email & number' do
        params.merge!({email: nil, area_code: nil, number: nil})
        expect(::Entities::Staff.new(params)).to be_a ::Entities::Staff
      end
    end

    context 'with valid coverage record params' do
      it 'should initialize entity object' do
        params.merge!(coverage_record: {is_applying_coverage: false})
        expect(::Entities::Staff.new(params)).to be_a ::Entities::Staff
      end
    end

    context 'with invalid params' do
      it 'should raise error without any params' do
        expect { ::Entities::Staff.new(params.except(:first_name)) }.to raise_error(Dry::Struct::Error, /:first_name is missing in Hash input/)
      end

      it 'should raise error with nil dob' do
        params.merge!({dob: nil})
        expect { ::Entities::Staff.new(params) }.to raise_error(Dry::Struct::Error, /has invalid type for :dob/)
      end

      context 'with invalid coverage record params' do
        it 'should not initialize entity object' do
          params.merge!(coverage_record: {is_applying_coverage: 'false'})
          expect { ::Entities::Staff.new(params) }.to raise_error(Dry::Struct::Error, /has invalid type for :is_applying_coverage/)
        end
      end
    end
  end
end
