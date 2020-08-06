# frozen_string_literal: true

module Parsers::Xml::Cv
  class EmailParser
    include HappyMapper

    register_namespace 'ridp', 'http://openhbx.org/api/terms/1.0'
    namespace 'ridp'
    tag 'email'

    element :type, String, tag: "type", :namespace => 'ridp'
    element :email_address, String, tag: "email_address", :namespace => 'ridp'

    def to_hash
      response = {
        email_address: email_address
      }
      response[:kind] = type.split("#").last if type
      response
    end
  end
end