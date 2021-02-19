# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Validators::StaffContract, type: :model, dbclean: :after_each do

  before :all do
    DatabaseCleaner.clean
  end

  let(:params) do
    {
      person_id: 'id', first_name: 'test', last_name: 'test'
    }
  end

  context 'success case' do
    context 'with coverage record' do

      it 'should success with is applying for coverage' do
        result = subject.call(params.merge!({coverage_record: {is_applying_coverage: false, address: {}, email: {}}}))
        expect(result.success?).to be_truthy
      end
    end

    context 'without coverage record key' do
      it 'should success' do
        result = subject.call(params)
        expect(result.success?).to be_truthy
      end
    end
  end

  context 'failure case' do

    context 'without required keys' do

      it 'should return failure' do
        result = subject.call(params.except(:first_name))
        expect(result.failure?).to be_truthy
      end
    end

    context 'with last name key as nil value' do
      it 'should return failure' do
        result = subject.call(params.merge!({last_name: nil}))
        expect(result.failure?).to be_truthy
      end
    end

    context 'with is coverage record' do
      it 'should fail without is applying for coverage' do
        result = subject.call(params.merge!({coverage_record: {}}))
        expect(result.failure?).to be_truthy
      end
    end
  end
end
