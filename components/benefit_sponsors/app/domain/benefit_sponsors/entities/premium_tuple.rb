# frozen_string_literal: true

module BenefitSponsors
  module Entities
    class PremiumTuple < Dry::Struct
      transform_keys(&:to_sym)

      attribute :age,    Types::Strict::Integer
      attribute :cost,   Types::Strict::Float

    end
  end
end