# frozen_string_literal: true

module BenefitSponsors
  module Validators
    module OfficeLocations
      # Phone Contract is to validate submitted params while persisting Phone
      class PhoneContract < Dry::Validation::Contract

        params do
          required(:kind).filled(:string)
          required(:area_code).filled(:string)
          required(:number).filled(:string)
          optional(:extension).maybe(:string)
          optional(:full_phone_number).maybe(:string)
        end

        rule(:number) do
          key.failure("Invalid Phones: Number can't be blank") unless /\A[0-9][0-9][0-9][0-9][0-9][0-9][0-9]\z/.match?(value)
        end

        rule(:kind) do
          key.failure('Invalid Phones: kind not valid') unless %w(home work).include?(value)
        end
      end
    end
  end
end
