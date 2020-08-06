# frozen_string_literal: true

module Parsers::Xml::Cv
  class CoverageHouseholdMembersParser
    include HappyMapper

    tag 'coverage_household_member'

    element :id, String, tag: 'id/ns0:id'
    element :person_surname, String, tag: 'person_name/ns0:person_surname'
    element :person_given_name, String, tag: 'person_name/ns0:person_given_name'

    def to_hash
      {
        id: id,
        person_name: {
          person_surname: person_surname,
          person_given_name: person_given_name
        }
      }
    end
  end
end
