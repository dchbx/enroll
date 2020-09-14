# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  module Families
    class CreateOrUpdate
      send(:include, Dry::Monads[:result, :do])

      PersonCandidate = Struct.new(:ssn, :dob)

      # @param [ Bson::ID ] application_id Application ID
      # @param [ Bson::ID ] family_id Family ID
      # @return [ Family ] family Family
      def call(applicant_params:, family_id:)
        family = yield find_family(family_id)
        family, applicant_family_mapping = yield create_family_member(applicant_params, family)

        Success(family, applicant_family_mapping)
      end

      private

      def sanitize_params(applicant_params)
        dob_value = applicant_params[:dob]

        applicant_params.merge!(dob: dob_value.strftime('%d/%m/%Y')) unless dob_value.is_a?(String)
      end

      def find_family(family_id)
        family = Family.find(family_id)
        Success(family)
      rescue StandardError
        Failure("Unable to find Family with ID #{family_id}.")
      end

      def create_family_member(applicant_attributes, family)
        applicant_id_mappings = {}

        applicant_params = sanitize_params(applicant_attributes)
        candidate = PersonCandidate.new(applicant_params[:ssn], applicant_params[:dob])

        if applicant_params[:family_member_id].present?
          applicant_id_mappings[applicant_params[:_id]] = {
              family_member_id: applicant_params[:family_member_id],
              person_hbx_id: applicant_params[:person_hbx_id]
          }
        else

          person = Person.match_existing_person(candidate)

          if person.blank?
            new_person_params = extract_person_params(applicant_params)

            person_valid_params = Validators::PersonContract.new.call(new_person_params)
            person_params = Entities::Person.new(person_valid_params.to_h)

            person = Person.new(person_params) #if person_valid_params.success?

            return false unless try_create_person(person)
          end

          #TODO family member create/update
          #family_member
          # family_member = family.relate_new_member(person, applicant_params[:relationship])

          #consumer_role
          consumer_role_valid_params = Validators::Families::ConsumerRoleContract.new.call(extract_consumer_role_params(applicant_params))
          consumer_role_params = Entities::ConsumerRole.new(consumer_role_valid_params.to_h)
          family_member.family.build_consumer_role(family_member, consumer_role_params) if applicant_params[:is_consumer_role]
          raise 'Consumer Role missing!!' unless person.consumer_role

          #TODO vlp document create/update
          # #vlp_document
          # vlp_document_valid_params = Validators::Families::VlpDocumentsContract.new.call( extract_vlp_params(applicant_params))
          # vlp_document_params = Entities::VlpDocuments.new(vlp_document_valid_params.to_h)
          # create_vlp_document(person, applicant_params[:vlp_subject], vlp_document_params) if applicant_params[:vlp_subject].present?
          #
          # family.save!
          # family.primary_person.save!
          # applicant_id_mappings = {
          #     family_member_id: family_member.id,
          #     person_hbx_id: person.hbx_id
          # }
        end

        Success([family, applicant_id_mappings])
      end

      def create_vlp_document(person, subject, vlp_attrs)
        vlp_document = person.consumer_role.find_document(subject)
        vlp_document.assign_attributes(vlp_attrs)
        vlp_document.save!
        person.consumer_role.active_vlp_document_id = vlp_document.id
        person.save!
      end

      def create_or_update_associations(person, applicant_params, assoc)
        records = applicant_params[assoc.to_sym]
        return if records.empty?

        records.each do |attrs|
          address_matched = person.send(assoc).detect {|adr| adr.kind == attrs[:kind]}
          if address_matched
            address_matched.update(attrs)
          else
            person.send(assoc).create(attrs)
          end
        end
      end

      def extract_person_params(applicant_params)
        attributes = [
            :first_name, :last_name, :middle_name, :name_pfx, :name_sfx, :gender, :dob,
            :ssn, :no_ssn, :race, :ethnicity, :language_code, :is_incarcerated, :citizen_status,
            :tribal_id, :no_dc_address, :is_homeless, :is_temporarily_out_of_state, :same_with_primary,
            :addresses, :phones, :emails
        ]

        applicant_params.slice(*attributes)
      end

      def extract_consumer_role_params(applicant_params)
        attributes = [:citizen_status, :vlp_document_id, :is_applying_coverage]
        applicant_params.slice(*attributes)
      end

      def dob=(val)
        @dob = begin
          Date.strptime(val, "%Y-%m-%d")
        rescue StandardError
          nil
        end
      end

      def extract_vlp_params(applicant_params)
        attributes = [
            :vlp_subject, :alien_number, :i94_number, :visa_number, :passport_number, :sevis_id,
            :naturalization_number, :receipt_number, :citizenship_number, :card_number,
            :country_of_citizenship, :expiration_date, :issuing_country, :status
        ]

        applicant_params.slice(*attributes).reject {|_name, value| value.blank?}
      end

      def try_create_person(person)
        person.save.tap do
          bubble_person_errors(person)
        end
      end

      def bubble_person_errors(person)
        self.errors.add(:ssn, person.errors[:ssn]) if person.errors.key?(:ssn)
      end
    end
  end
end
