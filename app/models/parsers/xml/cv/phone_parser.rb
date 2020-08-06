# frozen_string_literal: true

module Parsers::Xml::Cv
  class PhoneParser
    include HappyMapper

    register_namespace 'ridp', 'http://openhbx.org/api/terms/1.0'
    namespace 'ridp'

    element :type, String, tag: "type", :namespace => 'ridp'
    element :country_code, String, tag: "country_code", :namespace => 'ridp'
    element :area_code, String, tag: "area_code", :namespace => 'ridp'
    element :phone_number, String, tag: "phone_number", :namespace => 'ridp'
    element :full_phone_number, String, tag: "full_phone_number", :namespace => 'ridp'
    element :extension, String, tag: "extension", :namespace => 'ridp'
    element :is_preferred, String, tag: "is_preferred", :namespace => 'ridp'

    def to_hash
      response = {
        area_code: area_code,
        country_code: country_code,
        extension: extension,
        phone_number: full_phone_number
      }
      response[:kind] = type.split("#").last if type
      response
    end
  end
end