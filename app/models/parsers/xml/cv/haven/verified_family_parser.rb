# frozen_string_literal: true

module Parsers
  module Xml
    module Cv
      module Haven
        class VerifiedFamilyParser
          include HappyMapper
          register_namespace 'n1', 'http://openhbx.org/api/terms/1.0'
          namespace 'n1'

          tag 'external_verified_family'

          element :integrated_case_id, String, tag: 'id/n1:id'
          has_many :family_members, Parsers::Xml::Cv::Haven::FamilyMembersParser, tag: 'family_member'
          element :primary_family_member_id, String, tag: 'primary_family_member_id/n1:id'
          has_many :households, Parsers::Xml::Cv::Haven::HouseholdsParser, tag: 'household', namespace: 'n1'
          has_many :broker_accounts, Parsers::Xml::Cv::Haven::FamilyBrokerAccountsParser, tag: 'broker_account', namespace: 'n1'
          element :e_case_id, String
          element :fin_app_id, String, tag: 'fin_app_id', namespace: 'n1'
          element :haven_app_id, String, tag: 'haven_app_id', namespace: 'n1'
          element :haven_ic_id, String, tag: 'haven_ic_id', namespace: 'n1'
        end
      end
    end
  end
end
