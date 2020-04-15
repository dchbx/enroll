# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HbxEnrollments::Validators::IvlContract, dbclean: :after_each do
  let(:params) do
    {kind: "individual", enrollment_kind: "open_enrollment", coverage_kind: "health",
     changing: false, effective_on: TimeKeeper.date_of_record, hbx_id: "1234", submitted_at: TimeKeeper.date_of_record,
     aasm_state: "coverage_terminated", is_active: true, review_status: "incomplete",
     is_any_enrollment_member_outstanding: false, elected_amount: {cents: 0.0, currency_iso: "USD"},
     applied_aptc_amount: {cents: 0.0, currency_iso: "USD"}, applied_premium_credit: {cents: 0.0, currency_iso: "USD"},
     elected_premium_credit: {cents: 0.0, currency_iso: "USD"}, elected_aptc_pct: 0.0,
     enrollment_signature: '', consumer_role_id: BSON::ObjectId.new, resident_role_id: BSON::ObjectId.new,
     plan_id: BSON::ObjectId.new, carrier_profile_id: BSON::ObjectId.new, benefit_coverage_period_id: BSON::ObjectId.new,
     benefit_package_id: BSON::ObjectId.new, special_verification_period: TimeKeeper.date_of_record,
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
      @result = subject.call(params.except(:consumer_role_id))
    end

    it 'should return any errors' do
      expect(@result.errors.to_h).not_to be_empty
    end

    it 'should return any errors' do
      expect(@result.errors.to_h).to eq({:consumer_role_id => ["is missing"]})
    end
  end
end