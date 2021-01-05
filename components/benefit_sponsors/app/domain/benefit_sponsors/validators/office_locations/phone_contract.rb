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
      end
    end
  end
end
