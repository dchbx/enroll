# frozen_string_literal: true

module BenefitSponsors
  module Entities
    class EnrollmentEligibility < Dry::Struct
      transform_keys(&:to_sym)

      attribute :benefit_sponsorship_id,          Types::Bson
      attribute :effective_date,                  Types::Strict::Date
      attribute :application_type,                Types::Strict::String

    end
  end
end