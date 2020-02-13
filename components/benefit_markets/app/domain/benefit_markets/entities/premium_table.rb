# frozen_string_literal: true

module BenefitMarkets
  module Entities
    class PremiumTable < Dry::Struct
      transform_keys(&:to_sym)

      attribute :effective_period,    Types::CustomRange
      # attribute :rating_area,         RatingArea
      attribute :premium_tuples,      Types::Array.of(PremiumTuple).meta(omittable: true)

    end
  end
end