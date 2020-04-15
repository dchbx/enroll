# frozen_string_literal: true

require "rails_helper"

RSpec.describe HbxEnrollments::Entities::IvlEnrollment, dbclean: :after_each do
  describe 'with valid arguments' do
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
       hbx_enrollment_members: [{applicant_id: BSON::ObjectId.new,
                                 is_subscriber: true, applied_aptc_amount: {cents: 0.0, currency_iso: "USD"},
                                 eligibility_date: TimeKeeper.date_of_record, coverage_start_on: TimeKeeper.date_of_record}],
       invalid_key: "invalid"}
    end

    it 'should initialize' do
      expect(HbxEnrollments::Entities::IvlEnrollment.new(params)).to be_a HbxEnrollments::Entities::IvlEnrollment
    end

    it 'should not raise error' do
      expect { HbxEnrollments::Entities::IvlEnrollment.new(params) }.not_to raise_error
    end

    it 'should list all valid args' do
      expect(HbxEnrollments::Entities::IvlEnrollment.new(params).to_h.keys).to eq [:kind,
                                                                                   :enrollment_kind,
                                                                                   :coverage_kind,
                                                                                   :changing,
                                                                                   :effective_on,
                                                                                   :hbx_id,
                                                                                   :submitted_at,
                                                                                   :aasm_state,
                                                                                   :is_active,
                                                                                   :review_status,
                                                                                   :external_enrollment,
                                                                                   :family_id,
                                                                                   :household_id,
                                                                                   :product_id,
                                                                                   :issuer_profile_id,
                                                                                   :hbx_enrollment_members,
                                                                                   :is_any_enrollment_member_outstanding,
                                                                                   :elected_amount,
                                                                                   :elected_premium_credit,
                                                                                   :applied_premium_credit,
                                                                                   :applied_aptc_amount,
                                                                                   :elected_aptc_pct,
                                                                                   :enrollment_signature,
                                                                                   :consumer_role_id,
                                                                                   :resident_role_id,
                                                                                   :plan_id,
                                                                                   :carrier_profile_id,
                                                                                   :benefit_coverage_period_id,
                                                                                   :benefit_package_id,
                                                                                   :special_verification_period]
    end

    it 'should not include extra arg' do
      expect(HbxEnrollments::Entities::IvlEnrollment.new(params).to_h.keys.include?(:invalid_key)).to eq false
    end
  end

  describe 'with invalid arguments' do
    it 'should raise error' do
      expect { subject }.to raise_error(Dry::Struct::Error, /:kind is missing in Hash input/)
    end
  end
end