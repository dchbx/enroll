# frozen_string_literal: true

module Parsers::Xml::Cv
  class BrokerAgencyParser
    include HappyMapper
    register_namespace 'ridp', 'http://openhbx.org/api/terms/1.0'
    namespace 'ridp'
    tag 'broker_agency'

    element :id, String, :tag => 'id/ridp:id'
    element :name, String, :tag => 'name'
    element :fein, String, :tag => 'fein'
    element :npn, String, :tag => 'npn'
    element :display_name, String, :tag => 'display_name'

    def to_hash
      {
        id: id,
        npn: npn,
        name: name,
        display_name: display_name,
        fein: fein
      }
    end
  end
end
