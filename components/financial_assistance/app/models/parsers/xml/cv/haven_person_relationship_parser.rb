# frozen_string_literal: true

module Parsers
  module Xml
    module Cv
      class HavenPersonRelationshipParser
        include HappyMapper

        register_namespace 'ns0', 'http://openhbx.org/api/terms/1.0'
        namespace 'ns0'
        tag 'person_relationship'

        element :object_individual_id, String, tag: "object_individual/ns0:id"
        element :relationship_uri, String, tag: "relationship_uri"
      end
    end
  end
end
