module Parsers::Xml::Cv
  class HavenIndividualParser
    include HappyMapper
    register_namespace 'n1', 'http://openhbx.org/api/terms/1.0'
    namespace 'n1'

    tag 'individual'
    element :individual_id, String, tag: 'id/n1:id'
    has_one :person, Parsers::Xml::Cv::HavenPersonParser, tag: 'person', namespace: 'n1'
    has_one :person_demographics, Parsers::Xml::Cv::HavenPersonDemographicsParser, tag: 'person_demographics'
  end
end