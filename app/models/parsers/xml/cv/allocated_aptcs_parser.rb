# frozen_string_literal: true

module Parsers::Xml::Cv
  class AllocatedAptcsParser
    include HappyMapper

    tag 'allocated_aptc'

    element :calendar_year, String
    element :total_amount, String

    def to_hash
      {
        calendar_year: calendar_year,
        total_amount: total_amount
      }
    end
  end
end
