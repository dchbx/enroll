# frozen_string_literal: true

module BenefitSponsors
  module Validators
    module OfficeLocations
      # Office Location Contract is to validate submitted params while persisting Office Location
      class OfficeLocationContract < Dry::Validation::Contract

        params do
          required(:address).filled(:hash)
          required(:phone).filled(:hash)
        end

        rule(:address).each do
          if key? && value
            result = BenefitSponsors::Validators::AddressContract.new.call(value)
            key.failure(text: "invalid office location", error: result.errors.to_h) if result&.failure?
          end
        end

        rule(:phone).each do
          if key? && value
            result = BenefitSponsors::Validators::PhoneContract.new.call(value)
            key.failure(text: "invalid office location", error: result.errors.to_h) if result&.failure?
          end
        end
      end
    end
  end
end
