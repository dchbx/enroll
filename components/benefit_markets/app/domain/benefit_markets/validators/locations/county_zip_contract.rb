# frozen_string_literal: true

module BenefitMarkets
  module Validators
    module Locations
      class CountyZipContract < Dry::Validation::Contract

        params do
          required(:_id).filled(Types::Bson)
          required(:county_name).filled(:string)
          required(:zip).filled(:string)
          required(:state).filled(:string)
        end

      end
    end
  end
end