# frozen_string_literal: true

module Parsers::Xml::Cv
  class IncomesParser
    include HappyMapper

    tag 'income'

    element :amount, String
    element :type, String
    element :frequency, String
    element :start_date, Date
    element :end_date, Date
    element :submitted_date, DateTime

    def to_hash
      {
        amount: amount,
        type: type.split('#').last,
        freqeuncy: frequency.split('#').last,
        start_date: start_date,
        end_date: end_date,
        submitted_date: submitted_date
      }
    end
  end
end
