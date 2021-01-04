# frozen_string_literal: true

module BenefitSponsors
  module Validators
    # Phone Contract is to validate submitted params while persisting Phone
    class PhoneContract < Dry::Validation::Contract

      params do
        required(:kind).filled(:string)
        required(:area_code).filled(:string)
        required(:number).filled(:string)
      end
    end
  end
end
