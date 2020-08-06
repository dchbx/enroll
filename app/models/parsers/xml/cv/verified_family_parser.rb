# frozen_string_literal: true

module Parsers::Xml::Cv
  class VerifiedFamilyParser
    include HappyMapper
    register_namespace 'ns0', 'http://openhbx.org/api/terms/1.0'
    namespace 'ns0'

    tag 'external_verified_family'

    element :integrated_case_id, String, tag: 'id/ns0:id'
    has_many :family_members, Parsers::Xml::Cv::FamilyMembersParser, tag: 'family_member'
    element :primary_family_member_id, String, tag: 'primary_family_member_id/ns0:id'
    has_many :households, Parsers::Xml::Cv::HouseholdsParser, tag: 'household', namespace: 'ns0'
    has_many :broker_accounts, Parsers::Xml::Cv::FamilyBrokerAccountsParser, tag: 'broker_account', namespace: 'ns0'
    element :submitted_at, DateTime
    element :is_active, Boolean
    element :created_at, DateTime


    def to_hash
      {
        integrated_case_id: integrated_case_id,
        family_members: family_members.map(&:to_hash),
        primary_family_member_id: primary_family_member_id,
        households: households.map(&:to_hash),
        submitted_at: submitted_at,
        is_active: is_active,
        created_at: created_at
      }
    end
  end
end
