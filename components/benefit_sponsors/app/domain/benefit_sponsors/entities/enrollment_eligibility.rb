# frozen_string_literal: true

module BenefitSponsors
  module Entities
    class EnrollmentEligibility < Dry::Struct
      transform_keys(&:to_sym)

    end
  end
end