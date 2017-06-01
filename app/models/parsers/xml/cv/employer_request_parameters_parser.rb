module Parsers::Xml::Cv
  class EmployerRequestParametersParser

    include HappyMapper
    register_namespace 'ridp', 'http://openhbx.org/api/terms/1.0'
    namespace 'ridp'
    tag 'parameters'

    element :first_name, String, tag: "person_name/ridp:person_given_name", :namespace => 'ridp'
    element :last_name, String, tag: "person_name/ridp:person_surname", :namespace => 'ridp'
    element :ssn, String, tag: "ssn", :namespace => 'ridp'
    element :dob, String, tag: "dob", :namespace => 'ridp'

    def to_hash
      {
          first_name: first_name,
          last_name: last_name,
          ssn: ssn,
          dob: dob
      }
    end

  end
end