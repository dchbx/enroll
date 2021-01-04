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
          required(:office_locations).schema do
            required(:address).maybe(:hash)
            required(:phone).maybe(:hash)
          end
        end

        rule(:office_locations) do
          if key? && value
            address = value[:address]
            phone = value[:phone]
            if address&.is_a?(Hash)
              result = BenefitSponsors::Validators::OfficeLocations::AddressContract.new.call(address)
              key.failure(text: "invalid address", error: result.errors.to_h) if result&.failure?
            else
              key.failure(text: "invalid addresses. Expected a hash.")
            end

            if phone&.is_a?(Hash)
              result = BenefitSponsors::Validators::OfficeLocations::PhoneContract.new.call(phone)
              key.failure(text: "invalid phone", error: result.errors.to_h) if result&.failure?
            else
              key.failure(text: "invalid phone. Expected a hash.")
            end
          end
        end
      end
    end
  end
end
