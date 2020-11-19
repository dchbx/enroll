# frozen_string_literal: true

module Validators
  module HbxEnrollments
    class HbxEnrollmentMemberContract < Dry::Validation::Contract

      params do
        required(:applicant_id).filled(Types::Bson)
        optional(:carrier_member_id).maybe(Types::Bson)
        required(:is_subscriber).filled(:bool)
        optional(:premium_amount).maybe(:float)
        optional(:applied_aptc_amount).maybe(:float)
        required(:eligibility_date).filled(:date)
        required(:coverage_start_on).filled(:date)
        optional(:coverage_end_on).maybe(:date)
      end
    end
  end
end
