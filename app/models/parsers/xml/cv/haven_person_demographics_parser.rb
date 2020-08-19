module Parsers::Xml::Cv
  class HavenPersonDemographicsParser
    include HappyMapper

    register_namespace 'ridp', 'http://openhbx.org/api/terms/1.0'
    tag 'person_demographics'
    namespace 'ridp'

    element :ssn, String, tag: "ssn"
    element :sex, String, tag: "sex"
    element :birth_date, String, tag: "birth_date"
    # element :death_date, String, tag: "death_date"
    # element :ethnicity, String, tag: "ethnicity"
    # element :race, String, tag: "race"
    # element :marital_status, String, tag: "marital_status"
    # element :citizen_status, String, tag: "citizen_status"
    # element :is_state_resident, Boolean, tag: "is_state_resident"
    # element :is_incarcerated, Boolean, tag: "is_incarcerated"
  end
end
