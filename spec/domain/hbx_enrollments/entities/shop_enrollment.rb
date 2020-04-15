# frozen_string_literal: true

require "rails_helper"

RSpec.describe HbxEnrollments::Entities::ShopEnrollment, dbclean: :after_each do
  describe 'with valid arguments' do
    let(:params) do
      {kind: "employer_sponsored", enrollment_kind: "open_enrollment", coverage_kind: "health",
       employee_role_id: BSON::ObjectId.new, benefit_group_id: BSON::ObjectId.new, benefit_group_assignment_id: BSON::ObjectId.new,
       benefit_sponsorship_id: BSON::ObjectId.new, sponsored_benefit_package_id: BSON::ObjectId.new, sponsored_benefit_id: BSON::ObjectId.new, rating_area_id: BSON::ObjectId.new,
       changing: false, effective_on: TimeKeeper.date_of_record, hbx_id: "1234", submitted_at: TimeKeeper.date_of_record,
       aasm_state: "coverage_terminated", is_active: true, review_status: "incomplete",
       external_enrollment: false, family_id: BSON::ObjectId.new, household_id: BSON::ObjectId.new,
       product_id: BSON::ObjectId.new, issuer_profile_id: BSON::ObjectId.new,
       hbx_enrollment_members: [{applicant_id: BSON::ObjectId.new,
                                 is_subscriber: true, applied_aptc_amount: {cents: 0.0, currency_iso: "USD"},
                                 eligibility_date: TimeKeeper.date_of_record, coverage_start_on: TimeKeeper.date_of_record}],
       invalid_key: "invalid"}
    end

    it 'should initialize' do
      expect(HbxEnrollments::Entities::ShopEnrollment.new(params)).to be_a HbxEnrollments::Entities::ShopEnrollment
    end

    it 'should not raise error' do
      expect { HbxEnrollments::Entities::ShopEnrollment.new(params) }.not_to raise_error
    end

    it 'should list all valid args' do
      expect(HbxEnrollments::Entities::ShopEnrollment.new(params).to_h.keys).to eq [:kind,
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
                                                                                    :employee_role_id,
                                                                                    :benefit_group_id,
                                                                                    :benefit_group_assignment_id,
                                                                                    :benefit_sponsorship_id,
                                                                                    :sponsored_benefit_package_id,
                                                                                    :sponsored_benefit_id,
                                                                                    :rating_area_id]
    end

    it 'should not include extra arg' do
      expect(HbxEnrollments::Entities::ShopEnrollment.new(params).to_h.keys.include?(:invalid_key)).to eq false
    end
  end

  describe 'with invalid arguments' do
    it 'should raise error' do
      expect { subject }.to raise_error(Dry::Struct::Error, /:kind is missing in Hash input/)
    end
  end
end