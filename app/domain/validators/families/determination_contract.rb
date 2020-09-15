# frozen_string_literal: true

module Validators
  module Families
    class DeterminationContract < Dry::Validation::Contract

      params do
        required(:max_aptc).filled(:hash)
        required(:csr_percent_as_integer).filled(:integer)
        required(:source).filled(:string)
        required(:aptc_csr_annual_household_income).filled(:hash)
        required(:aptc_annual_income_limit).filled(:hash)
        required(:csr_annual_income_limit).filled(:hash)
        required(:determined_at).filled(:date)
      end
    end
  end
end