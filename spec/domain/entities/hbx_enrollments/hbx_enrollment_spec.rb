# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Entities::HbxEnrollments::HbxEnrollment, dbclean: :after_each do

  let(:hbx_enrollment_member) do
    { applicant_id: BSON::ObjectId.new,
      is_subscriber: true,
      eligibility_date: TimeKeeper.date_of_record,
      coverage_start_on: TimeKeeper.date_of_record}
  end

  let(:valid_params) do
    { kind: 'individual',
      consumer_role_id: BSON::ObjectId.new,
      enrollment_kind: 'open_enrollment',
      coverage_kind: 'health',
      effective_on: TimeKeeper.date_of_record,
      hbx_enrollment_members: [hbx_enrollment_member]}
  end

  let(:contract) { Validators::HbxEnrollments::HbxEnrollmentContract.new }

  it 'contract validation should pass' do
    expect(contract.call(valid_params).to_h).to eq valid_params
  end

  context 'with valid params' do
    before do
      @result = described_class.new(valid_params)
    end

    it 'should return an object' do
      expect(@result).to be_a(Entities::HbxEnrollments::HbxEnrollment)
    end
  end

  context 'with invalid params' do
    it 'should return an error with message' do
      expect { described_class.new({}) }.to raise_error(Dry::Struct::Error, /:kind is missing in Hash input/)
    end
  end
end
