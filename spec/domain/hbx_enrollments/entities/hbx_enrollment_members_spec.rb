# frozen_string_literal: true

require "rails_helper"

RSpec.describe HbxEnrollments::Entities::HbxEnrollmentMembers, dbclean: :after_each do
  describe 'with valid arguments' do
    let(:params) do
      {applicant_id: BSON::ObjectId.new, is_subscriber: true, applied_aptc_amount: {cents: 0.0, currency_iso: "USD"},
       eligibility_date: TimeKeeper.date_of_record, coverage_start_on: TimeKeeper.date_of_record, invalid_key: "invalid"}
    end

    it 'should initialize' do
      expect(HbxEnrollments::Entities::HbxEnrollmentMembers.new(params)).to be_a HbxEnrollments::Entities::HbxEnrollmentMembers
    end

    it 'should not raise error' do
      expect { HbxEnrollments::Entities::HbxEnrollmentMembers.new(params) }.not_to raise_error
    end

    it 'should list all valid args' do
      expect(HbxEnrollments::Entities::HbxEnrollmentMembers.new(params).to_h.keys).to eq [:applicant_id, :is_subscriber, :premium_amount, :applied_aptc_amount, :eligibility_date, :coverage_start_on]
    end

    it 'should not include extra arg' do
      expect(HbxEnrollments::Entities::HbxEnrollmentMembers.new(params).to_h.keys.include?(:invalid_key)).to eq false
    end
  end

  describe 'with invalid arguments' do
    it 'should raise error' do
      expect { subject }.to raise_error(Dry::Struct::Error, /:applicant_id is missing in Hash input/)
    end
  end
end