# frozen_string_literal: true

module BenefitMarkets
  module Entities
    class PremiumTable < Dry::Struct
      transform_keys(&:to_sym)

      attribute :effective_period,    Types::Range
      attribute :rating_area_id,      Types::Bson
      attribute :premium_tuples,      Types::Array.of(BenefitMarkets::Entities::PremiumTuple).meta(omittable: true)

    end
  end
end