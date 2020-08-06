# frozen_string_literal: true

module Parsers::Xml::Cv
  class TaxHouseholdMembersParser
    include HappyMapper

    tag 'tax_household_member'

    element :id, String, tag: 'person/ns0:id/ns0:id'
    element :person_surname, String, tag: 'person/ns0:person_name/ns0:person_surname'
    element :person_given_name, String, tag: 'person/ns0:person_name/ns0:person_given_name'
    element :is_without_assistance, Boolean
    element :is_insurance_assistance_eligible, Boolean
    element :is_medicaid_chip_eligible, Boolean

    def to_hash
      {
        id: id,
        person_name: {
          person_surname: person_surname,
          person_given_name: person_given_name
        },
        is_without_assistance: is_without_assistance,
        is_insurance_assistance_eligible: is_insurance_assistance_eligible,
        is_medicaid_chip_eligible: is_medicaid_chip_eligible
      }
    end
  end
end
