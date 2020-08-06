# frozen_string_literal: true

module Parsers::Xml::Cv
  class DocumentResultsParser
    include HappyMapper

    namespace 'ridp'
    tag 'document_results'

    has_one :document_I20, Parsers::Xml::Cv::DocumentResultTypeParser
    has_one :document_I94, Parsers::Xml::Cv::DocumentResultTypeParser
    has_one :document_I327, Parsers::Xml::Cv::DocumentResultTypeParser
    has_one :document_I551, Parsers::Xml::Cv::DocumentResultTypeParser
    has_one :document_I571, Parsers::Xml::Cv::DocumentResultTypeParser
    has_one :document_I766, Parsers::Xml::Cv::DocumentResultTypeParser
    has_one :document_cert_of_citizenship, Parsers::Xml::Cv::DocumentResultTypeParser
    has_one :document_cert_of_naturalization, Parsers::Xml::Cv::DocumentResultTypeParser
    has_one :document_DS2019, Parsers::Xml::Cv::DocumentResultTypeParser
    has_one :document_foreign_passport, Parsers::Xml::Cv::DocumentResultTypeParser
    has_one :document_foreign_passport_I94, Parsers::Xml::Cv::DocumentResultTypeParser
    has_one :document_mac_read_I551, Parsers::Xml::Cv::DocumentResultTypeParser
    has_one :document_temp_I551, Parsers::Xml::Cv::DocumentResultTypeParser
    has_one :document_other_case_1, Parsers::Xml::Cv::DocumentResultTypeParser
    has_one :document_other_case_2, Parsers::Xml::Cv::DocumentResultTypeParser


    def to_hash
      response = {}
      response[:document_cert_of_naturalization] = document_cert_of_naturalization.to_hash if document_cert_of_naturalization
      response[:document_I94] = document_I94.to_hash if document_I94
      response[:document_I327] = document_I327.to_hash if document_I327
      response[:document_I551] = document_I551.to_hash if document_I551
      response[:document_I571] = document_I571.to_hash if document_I571
      response[:document_cert_of_naturalization] = document_cert_of_naturalization.to_hash if document_cert_of_naturalization
      response[:document_cert_of_citizenship] = document_cert_of_citizenship.to_hash if document_cert_of_citizenship
      response[:document_DS2019] = document_DS2019.to_hash if document_DS2019
      response[:document_foreign_passport] = document_foreign_passport.to_hash if document_foreign_passport
      response[:document_foreign_passport_I94] = document_foreign_passport_I94.to_hash if document_foreign_passport_I94
      response[:document_mac_read_I551] = document_mac_read_I551.to_hash if document_mac_read_I551
      response[:document_temp_I551] = document_temp_I551.to_hash if document_temp_I551
      response[:document_other_case_1] = document_other_case_1.to_hash if document_other_case_1
      response[:document_other_case_2] = document_other_case_2.to_hash if document_other_case_2
      response
    end

  end
end