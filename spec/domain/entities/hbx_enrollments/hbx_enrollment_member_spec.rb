# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Entities::HbxEnrollments::HbxEnrollmentMember, dbclean: :after_each do

  let(:valid_params) do
    { applicant_id: BSON::ObjectId.new,
      is_subscriber: true,
      eligibility_date: TimeKeeper.date_of_record,
      coverage_start_on: TimeKeeper.date_of_record}
  end

  let(:contract) { Validators::HbxEnrollments::HbxEnrollmentMemberContract.new }

  it 'contract validation should pass' do
    expect(contract.call(valid_params).to_h).to eq valid_params
  end

  context 'with valid params' do
    before do
      @result = described_class.new(valid_params)
    end

    it 'should return an object' do
      expect(@result).to be_a(Entities::HbxEnrollments::HbxEnrollmentMember)
    end
  end

  context 'with invalid params' do
    it 'should return an error with message' do
      expect { described_class.new({}) }.to raise_error(Dry::Struct::Error, /:applicant_id is missing in Hash input/)
    end
  end
end
