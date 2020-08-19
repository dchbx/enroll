module Parsers::Xml::Cv
  class HavenTaxHouseholdMembersParser
    include HappyMapper
    register_namespace 'n1', 'http://openhbx.org/api/terms/1.0'
    tag 'tax_household_member'

    element :id, String, tag: 'id/n1:id'
    element :person_id, String, tag: 'person/n1:id/n1:id'
    element :person_surname, String, tag: 'person/n1:person_name/n1:person_surname'
    element :person_given_name, String, tag: 'person/n1:person_name/n1:person_given_name'
    element :is_consent_applicant, Boolean, tag: 'is_consent_applicant'
    # element :is_without_assistance, Boolean
    # element :is_insurance_assistance_eligible, Boolean
    # element :is_medicaid_chip_eligible, Boolean

  end
end
