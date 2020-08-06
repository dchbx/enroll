# frozen_string_literal: true

module Parsers::Xml::Cv
  class HouseholdsParser
    include HappyMapper

    tag 'household'

    element :integrated_case_id, String, tag: 'id/ns0:id'
    element :irs_group_id, String
    element :start_date, Date
    has_many :coverage_households, Parsers::Xml::Cv::CoverageHouseholdsParser, tag: 'coverage_household', namespace: 'ns0'
    has_many :tax_households, Parsers::Xml::Cv::TaxHouseholdsParser, tag: 'tax_household', namespace: 'ns0'
    element :submitted_at, DateTime
    element :is_active, Boolean
    element :created_at, DateTime

    def to_hash
      {
        integrated_case_id: integrated_case_id,
        irs_group_id: irs_group_id,
        start_date: start_date,
        coverage_households: coverage_households.map(&:to_hash),
        tax_households: tax_households.map(&:to_hash),
        submitted_at: submitted_at,
        is_active: is_active,
        created_at: created_at
      }
    end
  end
end
