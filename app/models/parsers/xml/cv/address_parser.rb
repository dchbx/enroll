# frozen_string_literal: true

module Parsers::Xml::Cv
  class AddressParser
    include HappyMapper
    register_namespace 'ridp', 'http://openhbx.org/api/terms/1.0'
    namespace 'ridp'

    tag 'address'

    element :type, String, tag: "type", :namespace => 'ridp'
    element :address_line_1, String, tag: "address_line_1", :namespace => 'ridp'
    element :address_line_2, String, tag: "address_line_2", :namespace => 'ridp'
    element :location_state, String, tag: "location_state", :namespace => 'ridp'
    element :location_city_name, String, tag: "location_city_name", :namespace => 'ridp'
    element :location_state_code, String, tag: "location_state_code", :namespace => 'ridp'
    element :location_postal_code, String, tag: "postal_code", :namespace => 'ridp'
    element :location_postal_extension_code, String, tag: "location_postal_extension_code", :namespace => 'ridp'
    element :location_country_name, String, tag: "location_country_name", :namespace => 'ridp'
    element :location_country_code, String, tag: "location_country_code", :namespace => 'ridp'
    element :address_full_text, String, tag: "address_full_text", :namespace => 'ridp'
    element :location, String, tag: "location", :namespace => 'ridp'

    def to_hash
      response = {
        address_1: address_line_1,
        address_2: address_line_2,
        city: location_city_name,
        state: location_state_code,
        country: location_country_name,
        location_state_code: location_state_code,
        zip: location_postal_code
      }

      response[:kind] = type.split("#").last if type
      response
    end
  end
end