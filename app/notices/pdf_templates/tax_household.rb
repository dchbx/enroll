module PdfTemplates
  class TaxHousehold
    include Virtus.model

    attribute :csr_percent_as_integer, Integer
    attribute :max_aptc, Float
    attribute :aptc_csr_annual_household_income, Float
    attribute :aptc_csr_monthly_household_income, Float
    attribute :aptc_annual_income_limit, Float
    attribute :csr_annual_income_limit, Float
    attribute :applied_aptc, Float

  end
end