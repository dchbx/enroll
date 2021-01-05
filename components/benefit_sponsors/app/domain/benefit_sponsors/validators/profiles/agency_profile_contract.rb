# frozen_string_literal: true

module BenefitSponsors
  module Validators
    module Profiles
      # Profile Contract is to validate submitted params while persisting agency profile
      class AgencyProfileContract < Dry::Validation::Contract

        params do
          optional(:market_kind).filled(:string)
          optional(:languages_spoken).maybe(:array)
          optional(:working_hours).maybe(:bool)
          optional(:accept_new_clients).maybe(:bool)
          required(:office_locations).array(:hash)
        end

        rule(:office_locations).each do
          if key? && value
            symbolized_value = value.deep_symbolize_keys
            result = Validators::OfficeLocations::OfficeLocationContract.new.call(symbolized_value)
            if result.failure?
              key.failure('Invalid office locations')
            end
          end
        end
      end
    end
  end
end
