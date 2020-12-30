# frozen_string_literal: true

module Parsers
  module Xml
    module Cv
      module Haven
        class PersonParser
          include HappyMapper
          register_namespace 'ridp', 'http://openhbx.org/api/terms/1.0'
          namespace 'ridp'

          tag 'person'

          element :hbx_id, String, tag: "id/ridp:id"

          element :person_surname, String, tag: "person_name/ridp:person_surname"

          element :person_given_name, String, tag: "person_name/ridp:person_given_name"

          element :name_last, String, tag: "person_name/ridp:person_surname"

          element :name_first, String, tag: "person_name/ridp:person_given_name"

          element :name_full, String, tag: "person_name/ridp:person_full_name"

          element :created_at, String, tag: "created_at"

        end
      end
    end
  end
end
