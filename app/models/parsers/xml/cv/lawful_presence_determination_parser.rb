module Parsers::Xml::Cv
  class LawfulPresenceDeterminationParser
    include HappyMapper

    tag 'lawful_presence_determination'

    element :response_code, String, tag:'response_code'
    element :legal_status, String, tag:'legal_status'
    element :employment_authorized, String, tag: 'employment_authorized'
    element :qualified_non_citizen_code, String, tag: 'qualified_non_citizen_code'
    has_one :document_results, Parsers::Xml::Cv::DocumentResultsParser, :tag => 'document_results', :namespace => 'ridp'

    def to_hash
      {
          response_code: response_code.split('#').last,
          legal_status: legal_status.split('#').last,
          employment_authorized: employment_authorized.split('#').last,
          document_results: document_results.to_hash,
          qualified_non_citizen_code: qualified_non_citizen_code,
      }
    end
  end
end