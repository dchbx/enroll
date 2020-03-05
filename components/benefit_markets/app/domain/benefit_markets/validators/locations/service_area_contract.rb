# frozen_string_literal: true

module BenefitMarkets
  module Validators
    module Locations
      class ServiceAreaContract < Dry::Validation::Contract

        params do
          required(:_id).filled(Types::Bson)
          required(:active_year).filled(:integer)
          required(:issuer_provided_title).filled(:string)
          required(:issuer_provided_code).filled(:string)
          required(:issuer_profile_id).filled(Types::Bson)
          optional(:issuer_hios_id).maybe(:string)
          optional(:county_zip_ids).maybe(:array)
          required(:covered_states).array(:string)
        end

      end
    end
  end
end