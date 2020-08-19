module Parsers::Xml::Cv
  class HavenMecVerificationsParser
    include HappyMapper
    register_namespace 'n1', 'http://openhbx.org/api/terms/1.0'
    namespace 'n1'

    tag 'mec_verification_result'

    element :mec_verification_result_id, String, tag: 'id/n1:id'
    has_one :individual, Parsers::Xml::Cv::HavenIndividualParser, tag: 'individual'
    element :response_code, String, tag: 'response_code'
    element :mec_verification_failed, Boolean, tag: 'mec_verification_failed'
  end
end