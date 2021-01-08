# frozen_string_literal: true

module BenefitSponsors
  module Validators
    module Employers
      # Coverage record Contract is to validate staff whether he is applying for coverage
      class CoverageRecordContract < Dry::Validation::Contract

        params do
          optional(:ssn).maybe(:string)
          optional(:dob).maybe(:date)
          optional(:hired_on).maybe(:date)
          optional(:gender).maybe(:string)
          required(:is_applying_coverage).value(:bool)
          required(:address).maybe(:hash)
          required(:email).maybe(:hash)
        end

        rule(:address) do
          if key? && value && values[:is_applying_coverage]
            address = value[:address]
            if address&.is_a?(Hash)
              result = BenefitSponsors::Validators::AddressContract.new.call(address)
              key.failure(text: "invalid address", error: result.errors.to_h) if result&.failure?
            else
              key.failure(text: "invalid addresses. Expected a hash.")
            end
          end
        end

        rule(:email) do
          if key? && value && values[:is_applying_coverage]
            email = value[:email]
            if email&.is_a?(Hash)
              result = BenefitSponsors::Validators::EmailContract.new.call(email)
              key.failure(text: "invalid email", error: result.errors.to_h) if result&.failure?
            else
              key.failure(text: "invalid emails. Expected a hash.")
            end
          end
        end
      end
    end
  end
end
