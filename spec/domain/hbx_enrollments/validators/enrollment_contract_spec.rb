# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HbxEnrollments::Validators::EnrollmentContract, dbclean: :after_each do
  let(:params) do
    {kind: "employer_sponsored", enrollment_kind: "open_enrollment", coverage_kind: "health",
     changing: false, effective_on: TimeKeeper.date_of_record, submitted_at: TimeKeeper.date_of_record,
     aasm_state: "coverage_terminated", is_active: true, review_status: "incomplete",
     external_enrollment: false, family_id: BSON::ObjectId.new, household_id: BSON::ObjectId.new,
     product_id: BSON::ObjectId.new, issuer_profile_id: BSON::ObjectId.new,
     hbx_enrollment_members: [{applicant_id: BSON::ObjectId.new, is_subscriber: true,
                               applied_aptc_amount: {cents: 0.0, currency_iso: "USD"},
                               eligibility_date: TimeKeeper.date_of_record, coverage_start_on: TimeKeeper.date_of_record}]}
  end

  context 'for success case' do
    before do
      @result = subject.call(params)
    end

    it 'should be a container-ready operation' do
      expect(subject.respond_to?(:call)).to be_truthy
    end

    it 'should return Dry::Validation::Result object' do
      expect(@result).to be_a ::Dry::Validation::Result
    end

    it 'should not return any errors' do
      expect(@result.errors.to_h).to be_empty
    end
  end

  context 'for failure case' do
    before do
      @result = subject.call(params.except(:kind))
    end

    it 'should return any errors' do
      expect(@result.errors.to_h).not_to be_empty
    end

    it 'should return any errors' do
      expect(@result.errors.to_h).to eq({:kind => ["is missing"]})
    end
  end
end