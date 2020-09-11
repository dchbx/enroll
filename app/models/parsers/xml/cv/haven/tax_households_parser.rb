# frozen_string_literal: true

module Parsers
  module Xml
    module Cv
      module Haven
        class TaxHouseholdsParser
          include HappyMapper
          register_namespace 'n1', 'http://openhbx.org/api/terms/1.0'
          tag 'tax_household'

          element :hbx_assigned_id, String, tag: 'id/n1:id'
          element :primary_applicant_id, String, tag: 'primary_applicant_id/n1:id'
          has_many :tax_household_members, Parsers::Xml::Cv::HavenTaxHouseholdMembersParser, tag: 'tax_household_member', namespace: 'n1'
          has_many :eligibility_determinations, Parsers::Xml::Cv::HavenEligibilityDeterminationsParser, tag: 'eligibility_determination', namespace: 'n1'
          element :start_date, Date
        end
      end
    end
  end
end
