# frozen_string_literal: true

module Parsers::Xml::Cv
  class FamilyMembersParser
    include HappyMapper

    tag 'family_member'
    namespace 'ns0'
    element :id, String, tag: 'id/ns0:id'
    has_one :person, Parsers::Xml::Cv::PersonParser, tag: 'person', namespace: 'ns0'
    has_many :person_relationships, Parsers::Xml::Cv::PersonRelationshipParser, tag: 'person_relationship', namespace: 'ns0'
    has_one :person_demographics, Parsers::Xml::Cv::PersonDemographicsParser, tag: 'person_demographics', namespace: 'ns0'
    element :is_primary_applicant, Boolean, tag: 'is_primary_applicant'
    element :is_consent_applicant, Boolean, tag: 'is_consent_applicant'
    element :is_coverage_applicant, Boolean, tag: 'is_coverage_applicant'
    has_many :financial_statements, Parsers::Xml::Cv::FinancialStatementsParser, tag: 'financial_statement', namespace: 'ns0'
    has_one :verifications, Parsers::Xml::Cv::VerificationsParser, tag: 'verifications', namespace: 'ns0'
    element :is_active, Boolean
    element :created_at, DateTime
    element :modified_at, DateTime

    def to_hash
      {
        id: id,
        person: person.to_hash,
        person_relationships: person_relationships.map(&:to_hash),
        person_demographics: person_demographics.to_hash,
        is_primary_applicant: is_primary_applicant,
        is_consent_applicant: is_consent_applicant,
        is_coverage_applicant: is_coverage_applicant,
        financial_statements: financial_statements.map(&:to_hash),
        verifications: verifications.to_hash,
        is_active: is_active,
        created_at: created_at,
        modified_at: modified_at
      }
    end
  end
end
