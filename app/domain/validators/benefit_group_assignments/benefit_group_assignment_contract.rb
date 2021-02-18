# frozen_string_literal: true

module Validators
  module BenefitGroupAssignments
    # This class checks and validates the incoming params
    # that are required to build a new benefit_group_assignment object,
    # if any of the checks or rules fail it returns a failure
    class BenefitGroupAssignmentContract < ::Dry::Validation::Contract

      params do
        required(:benefit_package_id).filled(Types::Bson)
        required(:start_on).filled(:date)

        optional(:end_on).maybe(:date)
        optional(:activated_at).maybe(:date)
        optional(:hbx_enrollment_id).maybe(Types::Bson)
        optional(:is_active).maybe(:bool)
      end
    end
  end
end
