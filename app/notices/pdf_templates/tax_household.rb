module PdfTemplates
  class TaxHousehold
    include Virtus.model

    attribute :csr_percent_as_integer, Integer
    attribute :max_aptc, Integer
    attribute :aptc_csr_annual_household_income, Integer
    attribute :aptc_annual_income_limit, Integer
    attribute :csr_annual_income_limit, Integer

  end
end
