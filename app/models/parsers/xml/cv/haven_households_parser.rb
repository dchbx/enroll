module Parsers::Xml::Cv
  class HavenHouseholdsParser
    include HappyMapper
    # register_namespace 'n1', 'http://openhbx.org/api/terms/1.0'

    tag 'household'

    element :id, String, tag: 'id/n1:id'
    element :irs_group_id, String
    element :start_date, Date
    # has_many :coverage_households, Parsers::Xml::Cv::CoverageHouseholdsParser, tag: 'coverage_household', namespace: 'n1'
    has_many :tax_households, Parsers::Xml::Cv::HavenTaxHouseholdsParser, tag: 'tax_household', namespace: 'n1'
    # element :submitted_at, DateTime
    # element :is_active, Boolean
    # element :created_at, DateTime

  end
end
