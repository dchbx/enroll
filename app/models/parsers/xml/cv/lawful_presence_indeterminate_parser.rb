# frozen_string_literal: true

module Parsers::Xml::Cv
  class LawfulPresenceIndeterminateParser
    include HappyMapper

    tag 'lawful_presence_indeterminate'

    element :response_code, String, tag: 'response_code'
    element :response_text, String, tag: 'response_text'

    def to_hash
      {
        response_code: response_code.split('#').last,
        response_text: response_text
      }
    end

  end
end
