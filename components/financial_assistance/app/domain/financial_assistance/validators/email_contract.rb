# frozen_string_literal: true

module FinancialAssistance
  module Validators
    class EmailContract < Dry::Validation::Contract

      params do
        required(:kind).filled(:string)
        required(:address).filled(:string)
      end
    end
  end
end