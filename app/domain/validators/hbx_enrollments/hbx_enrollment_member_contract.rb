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

      rule(:coverage_end_on, :coverage_start_on) do
        if key? && value
          if !value.is_a?(Date)
            key.failure('must be a date')
          elsif values[:coverage_end_on] < values[:coverage_start_on]
            key.failure('must be on or after coverage_start_on.')
          end
        end
      end
    end
  end
end
