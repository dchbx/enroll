# frozen_string_literal: true

module Parsers::Xml::Cv
  class FinancialStatementsParser
    include HappyMapper

    tag 'financial_statement'
    namespace 'ns0'
    element :tax_filing_status, String
    element :is_tax_filing_together, Boolean
    has_many :incomes, Parsers::Xml::Cv::IncomesParser, tag: 'income', namespace: 'ns0'

    def to_hash
      {
        tax_filing_status: tax_filing_status.split('#').last,
        is_tax_filing_together: is_tax_filing_together,
        incomes: incomes.map(&:to_hash)
      }
    end
  end
end
