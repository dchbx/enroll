# frozen_string_literal: true

module BenefitMarkets
  module Entities
    class RatingArea < Dry::Struct
      transform_keys(&:to_sym)

      attribute :_id,                                 Types::Bson
      attribute :active_year,                         Types::Strict::Integer
      attribute :exchange_provided_code,              Types::Strict::String
      attribute :county_zip_ids,                      Types::Strict::Array
      attribute :covered_states,                      Types::Strict::Array

    end
  end
end