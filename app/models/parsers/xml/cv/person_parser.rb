# frozen_string_literal: true

module Parsers::Xml::Cv
  class PersonParser
    include HappyMapper
    register_namespace 'ridp', 'http://openhbx.org/api/terms/1.0'
    namespace 'ridp'

    tag 'person'

    element :name_first, String,  tag: "person_name/ridp:person_given_name"

    element :name_last, String, tag: "person_name/ridp:person_surname"

    element :name_full, String, tag: "person_name/ridp:person_full_name"

    element :name_middle, String, tag: "person_name/ridp:person_middle_name"

    element :name_pfx, String, tag: "person_name/ridp:person_name_prefix_text"

    element :name_sfx, String, tag: "person_name/ridp:person_name_suffix_text"

    element :id, String, tag: "id/ridp:id"

    has_many :addresses, Parsers::Xml::Cv::AddressParser, :tag => 'address', :namespace => 'ridp'

    has_many :emails, Parsers::Xml::Cv::EmailParser, :tag => "email", :namespace => 'ridp'

    has_many :phones, Parsers::Xml::Cv::PhoneParser, :tag => "phone", :namespace => 'ridp'


    def to_hash
      response = {
        id: id,
        first_name: name_first,
        last_name: name_last,
        :name_pfx => name_pfx,
        :name_sfx => name_sfx,
        :middle_name => name_middle,
        :full_name => name_full
      }

      response[:addresses] = addresses.map(&:to_hash) if addresses
      response[:emails] = emails.map(&:to_hash) if emails
      response[:phones] = phones.map(&:to_hash) if phones
      response
    end
  end
end
