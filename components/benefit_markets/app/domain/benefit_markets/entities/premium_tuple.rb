# frozen_string_literal: true

module BenefitMarkets
  module Entities
    class PremiumTuple < Dry::Struct
      transform_keys(&:to_sym)

      attribute :_id,    Types::Bson
      attribute :age,    Types::Strict::Integer
      attribute :cost,   Types::Strict::Float

    end
  end
end