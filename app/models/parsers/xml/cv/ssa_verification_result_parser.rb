# frozen_string_literal: true

module Parsers::Xml::Cv
  class SsaVerificationResultParser
    include HappyMapper
    register_namespace 'ridp', 'http://openhbx.org/api/terms/1.0'
    namespace 'ridp'

    tag 'ssa_verification_result'

    element :response_code, String, tag: 'response_code', :namespace => 'ridp'
    element :response_text, String, tag: 'response_text', :namespace => 'ridp'
    element :ssn_verification_failed, String, tag: 'ssn_verification_failed', :namespace => 'ridp'
    element :ssn_verified, String, tag: 'ssn_verified', :namespace => 'ridp'
    element :death_confirmation, String, tag: 'death_confirmation', :namespace => 'ridp'
    element :citizenship_verified, String, tag: 'citizenship_verified', :namespace => 'ridp'
    element :incarcerated, String, tag: 'incarcerated', :namespace => 'ridp'
    has_one :individual, Parsers::Xml::Cv::IndividualParser, :tag => 'individual', :namespace => 'ridp'

    def to_hash
      response = {
        response_code: response_code,
        response_text: response_text,
        ssn_verification_failed: ssn_verification_failed,
        death_confirmation: death_confirmation,
        ssn_verified: ssn_verified,
        citizenship_verified: citizenship_verified,
        incarcerated: incarcerated,
        individual: individual.to_hash
      }
      response
    end
  end
end
