# frozen_string_literal: true

module Parsers::Xml::Cv
  class LawfulPresenceResponseParser
    include HappyMapper

    register_namespace 'ridp', 'http://openhbx.org/api/terms/1.0'
    namespace 'ridp'

    tag 'lawful_presence'

    element :case_number, String, tag: 'case_number', :namespace => 'ridp'
    has_one :lawful_presence_indeterminate, Parsers::Xml::Cv::LawfulPresenceIndeterminateParser, :tag => 'lawful_presence_indeterminate', :namespace => 'ridp'
    has_one :lawful_presence_determination, Parsers::Xml::Cv::LawfulPresenceDeterminationParser, :tag => 'lawful_presence_determination', :namespace => 'ridp'

    def to_hash
      response = {
        case_number: case_number
      }

      response[:lawful_presence_indeterminate] = lawful_presence_indeterminate.to_hash if lawful_presence_indeterminate
      response[:lawful_presence_determination] = lawful_presence_determination.to_hash if lawful_presence_determination
      response
    end
  end
end
