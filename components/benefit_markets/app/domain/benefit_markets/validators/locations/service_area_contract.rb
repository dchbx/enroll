# frozen_string_literal: true

module BenefitMarkets
  module Validators
    module Locations
      class ServiceAreaContract < Dry::Validation::Contract

        params do
          required(:active_year).filled(:integer)
          required(:issuer_provided_title).filled(:string)
          required(:issuer_provided_code).filled(:string)
          required(:issuer_profile_id).filled(Types::Bson)
          required(:issuer_hios_id).filled(:string)
          required(:county_zip_ids).array(:hash)
          required(:covered_states).array(:hash)
        end

      end
    end
  end
end