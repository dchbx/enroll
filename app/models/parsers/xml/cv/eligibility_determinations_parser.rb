# frozen_string_literal: true

module Parsers::Xml::Cv
  class EligibilityDeterminationsParser
    include HappyMapper

    tag 'eligibility_determination'

    element :id, String, tag: 'id/ns0:id'
    element :household_state, String
    element :maximum_aptc, String
    element :csr_percent, String
    element :determination_date, Date
    element :created_at, DateTime
    element :modified_at, DateTime

    def to_hash
      {
        id: id,
        household_state: household_state.split('#').last,
        maximum_aptc: maximum_aptc,
        csr_percent: csr_percent,
        determination_date: determination_date,
        created_at: created_at,
        modified_at: modified_at
      }
    end
  end
end
