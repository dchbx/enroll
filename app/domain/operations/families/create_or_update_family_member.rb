# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  module Families
    class CreateOrUpdateFamilyMember
      send(:include, Dry::Monads[:result, :do])

      # @param [ Bson::ID ] application_id Application ID
      # @param [ Bson::ID ] family_id Family ID
      # @return [ Family ] family Family

      def call(applicant_params:, family_id:)
        family = yield get_family(family_id)
        family, applicant_family_mapping = yield create_member(applicant_params, family)

        Success(family, applicant_family_mapping)
      end

      private

      def sanitize_params(applicant_params)
        dob_value = applicant_params[:dob]

        applicant_params.merge!(dob: dob_value.strftime('%d/%m/%Y')) unless dob_value.is_a?(String)
      end

      def get_family(family_id)
        Operations::Families::Find.new.call(family_id)
      end

      def create_member(applicant_attributes, family)
        applicant_id_mappings = {}
        applicant_params = sanitize_params(applicant_attributes)

        if applicant_params[:family_member_id].present?
          applicant_id_mappings[applicant_params[:_id]] = {
              family_member_id: applicant_params[:family_member_id],
              person_hbx_id: applicant_params[:person_hbx_id]
          }

          #update family member
        else

          person_result = create_or_update_person(applicant_params)

          if person_result.success?
            person = person_result.success
            family_member = create_or_update_family_member(person, family, applicant_params)
            create_or_update_consumer_role(applicant_params, family_member)
            create_or_update_vlp_document(applicant_params, person)
          else
            return person
          end
        end

        Success([family, applicant_id_mappings])
      end

      def create_or_update_person(applicant_params)
        # assign_person_address(existing_person)

        person = Operations::People::CreateOrUpdate.new.call(applicant_params)

        if person.success?
          Success(person)
        else
          Failure(person)
        end
      end

      def create_consumer_role(applicant_params, family_member)
        return unless applicant_params[:is_consumer_role]
        # assign_citizen_status
        Operation::Families::CreateOrUpdateConsumerRole(params: {applicant_params: applicant_params, family_member: family_member})
      end

      def create_or_update_family_member(person, family, applicant_params)
        family_member = family.relate_new_member(person, applicant_params[:relationship])
        family.save!

        family_member
      end

      def create_or_update_vlp_document(applicant_params, person)
        Operation::Families::CreateOrUpdateVlpDocument(params: {applicant_params: applicant_params, person: person})
      end
    end
  end
end
