module Parsers::Xml::Cv
  class HavenPersonRelationshipParser
    include HappyMapper

    register_namespace 'ns0', 'http://openhbx.org/api/terms/1.0'
    namespace 'ns0'
    tag 'person_relationship'

    # element :subject_individual_id, String, tag: "subject_individual/ns0:id"
    element :object_individual_id, String, tag: "object_individual/ns0:id"
    element :relationship_uri, String, tag: "relationship_uri"

    # def to_hash
    #   {
    #     subject_individual_id: subject_individual_id,
    #     relationship_uri: relationship_uri,
    #     object_individual_id: object_individual_id
    #   }
    # end
  end
end
