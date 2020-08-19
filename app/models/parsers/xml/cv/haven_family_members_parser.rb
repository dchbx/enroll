module Parsers::Xml::Cv
  class HavenFamilyMembersParser
    include HappyMapper
    register_namespace 'n1', 'http://openhbx.org/api/terms/1.0'

    tag 'family_member'
    namespace 'n1'
    element :id, String, tag: 'id/n1:id'
    has_one :person, Parsers::Xml::Cv::HavenPersonParser, tag: 'person', namespace: 'n1'
    # has_many :person_relationships, Parsers::Xml::Cv::HavenPersonRelationshipParser, tag: 'person_relationship', namespace: 'n1'
    has_one :person_demographics, Parsers::Xml::Cv::HavenPersonDemographicsParser, tag: 'person_demographics', namespace: 'n1'
    element :is_primary_applicant, Boolean, tag: 'is_primary_applicant'
    # element :is_consent_applicant, Boolean, tag: 'is_consent_applicant'
    element :is_coverage_applicant, Boolean, tag: 'is_coverage_applicant'
    element :is_without_assistance, Boolean, tag: 'is_without_assistance'
    element :is_insurance_assistance_eligible, Boolean, tag: 'is_insurance_assistance_eligible'
    element :is_medicaid_chip_eligible, Boolean, tag: 'is_medicaid_chip_eligible'
    element :is_non_magi_medicaid_eligible, Boolean, tag: 'is_non_magi_medicaid_eligible'
    element :magi_medicaid_monthly_household_income, String, tag: 'magi_medicaid_monthly_household_income'
    element :magi_medicaid_monthly_income_limit, String, tag: 'magi_medicaid_monthly_income_limit'
    element :magi_as_percentage_of_fpl, Integer, tag: 'magi_as_percentage_of_fpl'
    element :magi_medicaid_category, Boolean, tag: 'magi_medicaid_category'
    element :medicaid_household_size, Integer, tag: 'medicaid_household_size'
    element :is_totally_ineligible, Boolean, tag: 'is_totally_ineligible'
    # has_many :financial_statements, Parsers::Xml::Cv::FinancialStatementsParser, tag: 'financial_statement', namespace: 'n1'
    # has_one :verifications, Parsers::Xml::Cv::VerificationsParser, tag: 'verifications', namespace: 'n1'
    # element :is_active, Boolean
    element :created_at, DateTime
    # element :modified_at, DateTime

  end
end
