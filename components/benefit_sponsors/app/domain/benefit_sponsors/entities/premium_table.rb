# frozen_string_literal: true

module BenefitSponsors
  module Entities
    class PremiumTable < Dry::Struct
      transform_keys(&:to_sym)

      attribute :effective_period,    Types::Strict::Duration
      attribute :rating_area,         Types::RatingArea
      attribute :premium_tuples,      Types::PremiumTuple

    end
  end
end