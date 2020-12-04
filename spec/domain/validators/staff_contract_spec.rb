# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Validators::StaffContract, type: :model, dbclean: :after_each do

  before :all do
    DatabaseCleaner.clean
  end

  let(:params) do
    {
      first_name: 'test', last_name: 'test'
    }
  end

  context 'success case' do

    it 'should return success' do
      result = subject.call(params)
      expect(result.success?).to be_truthy
    end
  end

  context 'failure case' do

    context 'without required keys' do

      it 'should return failure' do
        result = subject.call(params.except(:first_name))
        expect(result.failure?).to be_truthy
      end
    end

    context 'with dob key as nil value' do
      it 'should return failure' do
        result = subject.call(params.merge!({dob: nil}))
        expect(result.failure?).to be_truthy
      end
    end
  end
end
