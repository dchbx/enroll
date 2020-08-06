# frozen_string_literal: true

module Parsers::Xml::Cv
  class CoverageHouseholdsParser
    include HappyMapper

    tag 'coverage_household'

    element :id, String, tag: 'id/ns0:id'
    element :start_date, Date
    has_many :coverage_household_members, Parsers::Xml::Cv::CoverageHouseholdMembersParser, tag: 'coverage_household_member', namespace: 'ns0'
    element :primary_member_id, String, tag: 'primary_member_id/ns0:id'
    element :submitted_at, DateTime
    element :is_active, Boolean
    element :created_at, DateTime

    def to_hash
      {
        id: id,
        start_date: start_date,
        coverage_household_members: coverage_household_members.map(&:to_hash),
        primary_member_id: primary_member_id,
        submitted_at: submitted_at,
        is_active: is_active,
        created_at: created_at
      }
    end
  end
end
