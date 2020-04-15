# frozen_string_literal: true

require "rails_helper"

RSpec.describe HbxEnrollments::Entities::Curreny, dbclean: :after_each do
  describe 'with valid arguments' do
    let(:params) do
      {cents: 0.0, currency_iso: "USD", invalid_key: "invalid"}
    end

    it 'should initialize' do
      expect(HbxEnrollments::Entities::Curreny.new(params)).to be_a HbxEnrollments::Entities::Curreny
    end

    it 'should not raise error' do
      expect { HbxEnrollments::Entities::Curreny.new(params) }.not_to raise_error
    end

    it 'should list all valid args' do
      expect(HbxEnrollments::Entities::Curreny.new(params).to_h.keys).to eq [:cents, :currency_iso]
    end

    it 'should not include extra arg' do
      expect(HbxEnrollments::Entities::Curreny.new(params).to_h.keys.include?(:invalid_key)).to eq false
    end
  end

  describe 'with no arguments' do
    it 'should return default values' do
      expect { subject }.not_to raise_error
      expect(subject.to_h.keys).to eq [:cents, :currency_iso]
    end
  end
end