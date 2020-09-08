module Parsers::Xml::Cv
  class HavenTaxHouseholdsParser
    include HappyMapper
    register_namespace 'n1', 'http://openhbx.org/api/terms/1.0'
    tag 'tax_household'

    element :hbx_assigned_id, String, tag: 'id/n1:id'
    element :primary_applicant_id, String, tag: 'primary_applicant_id/n1:id'
    # has_many :allocated_aptcs, Parsers::Xml::Cv::AllocatedAptcsParser, tag: 'allocated_aptc', namespace: 'n1'
    has_many :tax_household_members, Parsers::Xml::Cv::HavenTaxHouseholdMembersParser, tag: 'tax_household_member', namespace: 'n1'
    # element :tax_household_size, String, tag: 'tax_household_size/n1:total_count'
    has_many :eligibility_determinations, Parsers::Xml::Cv::HavenEligibilityDeterminationsParser, tag: 'eligibility_determination', namespace: 'n1'
    element :start_date, Date
    # element :submitted_at, DateTime
    # element :is_active, Boolean
    # element :created_at, DateTime

  end
end
