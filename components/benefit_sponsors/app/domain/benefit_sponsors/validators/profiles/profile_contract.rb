# frozen_string_literal: true

module BenefitSponsors
  module Validators
    module Profiles
      # Profile Contract is to validate submitted params while persisting agency profile
      class ProfileContract < Dry::Validation::Contract

        params do
          required(:is_benefit_sponsorship_eligible).filled(:bool)
          required(:contact_method).filled(:symbol)
          required(:office_locations).array(:hash)
        end

        rule(:office_locations).each do
          next unless key? && value

          symbolized_value = value.deep_symbolize_keys
          result = Validators::OfficeLocations::OfficeLocationContract.new.call(symbolized_value)
          key.failure(text: "Invalid Profile", error: result.errors.to_h) if result.failure?
        end
      end
    end
  end
end
