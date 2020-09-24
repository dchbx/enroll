# frozen_string_literal: true

module Notifier
  module MergeDataModels
    class TaxHousehold

      include Virtus.model

      attribute :csr_percent_as_integer, Integer
      attribute :max_aptc, Float
      attribute :aptc_csr_annual_household_income, Float
      attribute :aptc_csr_monthly_household_income, Float
      attribute :aptc_annual_income_limit, Float
      attribute :csr_annual_income_limit, Float
      attribute :applied_aptc, Float

      def self.stubbed_object
        Notifier::MergeDataModels::TaxHousehold.new(
          {
            csr_percent_as_integer: 87,
            max_aptc: 128.7,
            aptc_csr_annual_household_income: 12000.00,
            aptc_csr_monthly_household_income: 1000.00,
            aptc_annual_income_limit: 345.00,
            csr_annual_income_limit: 333.09,
            applied_aptc: 30.0
          }
        )
      end
    end
  end
end
