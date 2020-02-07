# frozen_string_literal: true

module BenefitMarkets
  module Entities
    module Locations
      class CountyZip < Dry::Struct
        transform_keys(&:to_sym)

        attribute :county_name,             Types::Strict::String
        attribute :zip,                     Types::Strict::String
        attribute :state,                   Types::Strict::String
      end
    end
  end
end