# frozen_string_literal: true

module BenefitSponsors
  module Validators
    class EnrollmentEligibilityContract < Dry::Validation::Contract

      params do
        required(:benefit_sponsorship_id).filled(Types::Bson)
        required(:effective_date).filled(:date)
        required(:application_type).filled(:string)
      end
    end
  end
end