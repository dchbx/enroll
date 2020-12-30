# frozen_string_literal: true

module BenefitMarkets
  module Validators
    module Locations
      class RatingAreaContract < Dry::Validation::Contract

        params do
          required(:_id).filled(Types::Bson)
          required(:active_year).filled(:integer)
          required(:exchange_provided_code).filled(:string)
          required(:county_zip_ids).array(:hash)
          required(:covered_states).array(:hash)
        end

      end
    end
  end
end