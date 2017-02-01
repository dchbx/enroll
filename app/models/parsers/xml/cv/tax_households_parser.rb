module Parsers::Xml::Cv
  class TaxHouseholdsParser
    include HappyMapper

    tag 'tax_household'

    element :id, String, tag: 'id/ns0:id'
    element :primary_applicant_id, String, tag: 'primary_applicant_id/ns0:id'
    has_many :allocated_aptcs, Parsers::Xml::Cv::AllocatedAptcsParser, tag: 'allocated_aptc', namespace: 'ns0'
    has_many :tax_household_members, Parsers::Xml::Cv::TaxHouseholdMembersParser, tag: 'tax_household_member', namespace: 'ns0'
    element :tax_household_size, String, tag: 'tax_household_size/ns0:total_count'
    has_many :eligibility_determinations, Parsers::Xml::Cv::EligibilityDeterminationsParser, tag: 'eligibility_determination', namespace: 'ns0'
    element :start_date, Date
    element :end_date, Date
    element :submitted_at, DateTime
    element :is_active, Boolean
    element :created_at, DateTime

    def to_hash
      {
        id: id,
        primary_applicant_id: primary_applicant_id,
        allocated_aptcs: allocated_aptcs.map(&:to_hash),
        tax_household_members: tax_household_members.map(&:to_hash),
        tax_household_size: tax_household_size,
        eligibility_determinations: eligibility_determinations.map(&:to_hash),
        start_date: start_date,
        end_date: end_date,
        submitted_at: submitted_at,
        is_active: is_active,
        created_at: created_at
      }
    end
  end
end
