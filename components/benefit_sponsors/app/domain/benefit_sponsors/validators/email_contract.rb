# frozen_string_literal: true

module BenefitSponsors
  module Validators
    # Email Contract is to validate submitted params while persisting Email
    class EmailContract < Dry::Validation::Contract

      params do
        required(:kind).filled(:string)
        required(:address).filled(:string)
      end
    end
  end
end
