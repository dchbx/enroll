# frozen_string_literal: true

module Parsers::Xml::Cv
  class DocumentResultTypeParser
    include HappyMapper

    namespace 'ridp'

    element :case_number, String
    element :response_code, String
    element :response_description_text, String
    element :tds_response_description_text, String
    element :entry_date, String
    element :admitted_to_date, String
    element :admitted_to_text, String
    element :country_birth_code, String
    element :country_citizen_code, String
    element :coa_code, String
    element :eads_expire_date, String
    element :elig_statement_code, String
    element :elig_statement_txt, String
    element :iav_type_code, String
    element :iav_type_text, String
    element :grant_date, String
    element :grant_date_reason_code, String

    def to_hash
      {
        case_number: case_number,
        response_code: response_code,
        response_description_text: response_description_text,
        tds_response_description_text: tds_response_description_text,
        entry_date: entry_date,
        admitted_to_date: admitted_to_date,
        admitted_to_text: admitted_to_text,
        country_birth_code: country_birth_code,
        country_citizen_code: country_citizen_code,
        coa_code: coa_code,
        eads_expire_date: eads_expire_date,
        elig_statement_code: elig_statement_code,
        elig_statement_txt: elig_statement_txt,
        iav_type_code: iav_type_code,
        iav_type_text: iav_type_text,
        grant_date: grant_date,
        grant_date_reason_code: grant_date_reason_code
      }
    end
  end
end
