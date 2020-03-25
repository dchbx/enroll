# frozen_string_literal: true

module BenefitSponsors
  module Entities
    class EnrollmentEligibility < Dry::Struct
      transform_keys(&:to_sym)

      attribute :market_kind,                     Types::Strict::Symbol
      attribute :benefit_sponsorship_id,          Types::Bson
      attribute :effective_date,                  Types::Strict::Date
      attribute :benefit_application_kind,        Types::Strict::Symbol

    end
  end
end