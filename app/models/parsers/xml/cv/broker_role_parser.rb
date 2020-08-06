# frozen_string_literal: true

module Parsers::Xml::Cv
  class BrokerRoleParser
    include HappyMapper
    register_namespace 'ridp', 'http://openhbx.org/api/terms/1.0'
    namespace 'ridp'
    tag 'broker_role'

    element :id, String, :tag => 'id/ridp:id'
    element :npn, String, :tag => 'npn'
    has_one :broker_agency, BrokerAgencyParser, :tag => 'broker_agency', :namespace => 'ridp'

    def to_hash
      {
        id: id,
        npn: npn,
        broker_agency: broker_agency.to_hash
      }
    end
  end
end
