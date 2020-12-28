# frozen_string_literal: true

RSpec.describe Notifier::ConsumerRoleHelper, :type => :helper do
  context "#tax_households_hash" do
    let(:tax_hh) do
      double(
        csr_percent_as_integer: "",
        max_aptc: "",
        aptc_csr_annual_household_income: "",
        aptc_csr_monthly_household_income: "",
        aptc_annual_income_limit: "",
        csr_annual_income_limit: "",
        applied_aptc: ""
      )
    end

    it "should return a Notifier::MergeDataModels:TaxHousehold object" do
      expect(helper.tax_households_hash(tax_hh).class).to eq(Notifier::MergeDataModels::TaxHousehold)
    end
  end

  context "#phone_number" do
    it "should return a phone number value for each legal name" do
      legal_names = ["BEST Life", "CareFirst", "Delta Dental", "Dominion", "Kaiser Permanente"]
      legal_names.each { |legal_name| expect(helper.phone_number(legal_name).length).to be > 1 }
    end
  end

  context "#format_currency" do

    it "should return blank string if blank value is passed" do
      expect(helper.format_currency("")).to eq("")
    end

    it "should return number to currency if value passed" do
      expect(helper.format_currency(10)).to eq("$10")
    end
  end
end
