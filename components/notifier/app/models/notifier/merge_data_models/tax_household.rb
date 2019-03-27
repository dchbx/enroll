module Notifier
  class MergeDataModels::TaxHousehold
    include Virtus.model

    attribute :csr_percent_as_integer, Integer
    attribute :max_aptc, Integer
    attribute :aptc_csr_annual_household_income, Integer
    attribute :aptc_annual_income_limit, Integer
    attribute :csr_annual_income_limit, Integer

    def self.stubbed_object
      Notifier::MergeDataModels::TaxHousehold.new({
        csr_percent_as_integer: 73,
        max_aptc: 1000,
        aptc_csr_annual_household_income: 8000,
        aptc_annual_income_limit: 10000,
        csr_annual_income_limit: 10000
      })
    end
  end
end