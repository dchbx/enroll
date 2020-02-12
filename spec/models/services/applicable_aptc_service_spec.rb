# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Services::ApplicableAptcService, type: :model, :dbclean => :after_each do
  context 'initialize' do
    it { expect(described_class.respond_to?(:new)).to eq true }

    it { expect(described_class.new('enrollment_id', 'selected_aptc', ['product_ids'])).to be_a Services::ApplicableAptcService }

    it { expect{described_class.new}.to raise_error(ArgumentError) }
  end

  context 'applicable_aptcs' do
    it { expect(described_class.new('enrollment_id', 'selected_aptc', ['product_ids']).respond_to?(:applicable_aptcs)).to eq true }

    it 'should raise error for bad enrollment id' do
      service_instance = described_class.new('enrollment_id', nil, ['product_ids'])
      error_message = 'Cannot find a valid enrollment with given enrollment id'
      expect{service_instance.applicable_aptcs}.to raise_error(RuntimeError, error_message)
    end

    it 'should raise error for bad selected aptc' do
      allow(HbxEnrollment).to receive(:where).and_return([double(family: 'family')])
      service_instance = described_class.new('enrollment_id', nil, ['product_ids'])
      expect{service_instance.applicable_aptcs}.to raise_error(RuntimeError, /Cannot process without selected_aptc:/)
    end

    it 'should raise error for bad product ids' do
      allow(HbxEnrollment).to receive(:where).and_return([double(family: 'family')])
      service_instance = described_class.new('enrollment_id', 10.00, [])
      expect{service_instance.applicable_aptcs}.to raise_error(RuntimeError, /Cannot process without selected_aptc:/)
    end
  end

  context 'elected_aptc_per_member' do
    it { expect(described_class.new('enrollment_id', 'selected_aptc', ['product_ids']).respond_to?(:elected_aptc_per_member)).to eq true }

    it 'should raise error for bad enrollment id' do
      service_instance = described_class.new('enrollment_id', nil, ['product_ids'])
      error_message = 'Cannot find a valid enrollment with given enrollment id'
      expect{service_instance.elected_aptc_per_member}.to raise_error(RuntimeError, error_message)
    end

    it 'should raise error for bad selected aptc' do
      allow(HbxEnrollment).to receive(:where).and_return([double(family: 'family')])
      service_instance = described_class.new('enrollment_id', nil, ['product_ids'])
      expect{service_instance.elected_aptc_per_member}.to raise_error(RuntimeError, /Cannot process without selected_aptc/)
    end
  end
end
