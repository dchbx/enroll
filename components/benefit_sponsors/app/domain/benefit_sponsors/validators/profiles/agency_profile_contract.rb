# frozen_string_literal: true

module BenefitSponsors
  module Validators
    module Profiles
      # Profile Contract is to validate submitted params while persisting agency profile
      class AgencyProfileContract < Dry::Validation::Contract

        params do
          required(:market_kind).filled(:string)
          optional(:languages_spoken).maybe(:array)
          optional(:working_hours).maybe(:bool)
          optional(:accept_new_clients).maybe(:bool)
          required(:office_locations).array(:hash)
        end

        rule(:office_locations).each do
          if key? && value
            result = BenefitSponsors::Validators::OfficeLocations::OfficeLocationContract.new.call(value)
            key.failure(text: "invalid office location", error: result.errors.to_h) if result&.failure?
          end
        end
      end
    end
  end
end
