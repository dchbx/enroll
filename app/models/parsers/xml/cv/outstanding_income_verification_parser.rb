module Parsers::Xml::Cv
  class OutstandingIncomeVerificationParser
    include HappyMapper
    register_namespace 'n1', 'http://openhbx.org/api/terms/1.0'
    namespace 'n1'

    tag 'external_verifications'

    element :external_verifications_id, String, tag: 'id/n1:id'
      element :primary_family_member_id, String, tag: 'primary_family_member_id/n1:id'
      element :fin_app_id, String, tag: 'fin_app_id'
      element :haven_app_id, String, tag: 'haven_app_id'
      has_many :verifications, Parsers::Xml::Cv::HavenIncomeVerificationsParser, tag: 'income_verification_result'
  end
end