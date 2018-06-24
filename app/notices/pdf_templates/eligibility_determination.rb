module PdfTemplates
  class EligibilityDetermination
    include Virtus.model

    attribute :csr_percent_as_integer, String
    attribute :max_aptc, String
    attribute :aptc_csr_annual_household_income, String
    attribute :aptc_annual_income_limit, String
    attribute :csr_annual_income_limit, String

    def shop?
      false
    end

    def general_agency?
      false
    end
  end
end