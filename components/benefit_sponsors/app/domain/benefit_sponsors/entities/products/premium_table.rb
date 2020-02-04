# frozen_string_literal: true

module BenefitSponsors
  module Entities
    module Products
      class PremiumTable < Dry::Struct
        transform_keys(&:to_sym)

        attribute :effective_period,    Types::Strict::Duration
        attribute :rating_area,         Types::RatingArea
        attribute :premium_tuples,      Types::Array.of(Products::PremiumTuple)

      end
    end
  end
end