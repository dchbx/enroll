# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  module FinancialAssistance
    class ParseApplicant

      # Input: FamilyMember
      # Output: Ruby Hash Applicant

      def call(params)
        values              = yield validate(params)
        financial_applicant = yield parse_family_member(values)
        Success(financial_applicant)
      end

      private

      def validate(params)
        Failure('Given family member is not a valid object') unless params[:family_member].is_a?(::FamilyMember)
        Failure('Given family member does not have a matching person') unless params[:family_member].person.present?

        Success(params)
      end

      def parse_family_member(values)
        Success(family_member_attributes(family_member))
      end

      def family_member_attributes(family_member)
        person_attributes(family_member.person).merge(family_member_id: family_member.id,
                                                      is_primary_applicant: family_member.is_primary_applicant,
                                                      is_consent_applicant: family_member.is_consent_applicant)
      end

      def person_attributes(person)
        attrs = person.attributes.slice(:first_name, :last_name, :middle_name, :name_pfx, :name_sfx, :gender, :ethnicity, :tribal_id, :no_ssn, :is_tobacco_user).symbolize_keys!
        attrs.merge!(person_hbx_id: person.hbx_id,
                     ssn: person.ssn,
                     dob: person.dob.strftime("%d/%m/%Y"),
                     is_applying_coverage: person.consumer_role.is_applying_coverage,
                     citizen_status: person.citizen_status,
                     is_consumer_role: true,
                     same_with_primary: false,
                     indian_tribe_member: person.consumer_role.is_tribe_member?,
                     is_incarcerated: person.is_incarcerated,
                     addresses: construct_association_fields(person.addresses),
                     phones: construct_association_fields(person.phones),
                     emails: construct_association_fields(person.emails))

        attrs.merge(vlp_document_params(person.consumer_role))
      end

      def vlp_document_params(consumer_role)
        return {} unless consumer_role.active_vlp_document
        consumer_role.active_vlp_document.attributes.slice(:vlp_subject,
                                                           :alien_number,
                                                           :i94_number,
                                                           :visa_number,
                                                           :passport_number,
                                                           :sevis_id,
                                                           :naturalization_number,
                                                           :receipt_number,
                                                           :citizenship_number,
                                                           :card_number,
                                                           :country_of_citizenship,
                                                           :expiration_date,
                                                           :issuing_country)
      end

      def construct_association_fields(records)
        records.collect{|record| record.attributes.except(:_id, :created_at, :updated_at, :tracking_version) }
      end
    end
  end
end
