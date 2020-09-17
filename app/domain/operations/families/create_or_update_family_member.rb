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

      def call(params)
        family_result = yield get_family(family_id: params[:family_id])
        family, person_family_member_mapping = yield create_member(params, family_result)

        Success([family, person_family_member_mapping])
      end

      private

      def sanitize_params(applicant_params)
        dob_value = applicant_params[:dob]

        applicant_params.merge!(dob: dob_value.strftime('%d/%m/%Y')) unless dob_value.is_a?(String)
        applicant_params
      end

      def get_family(family_id:)
        if family_id
          Operations::Families::Find.new.call(id: BSON::ObjectId(family_id))
        else
          Failure("family id is required")
        end
      end

      def create_member(applicant_attributes, family)
        applicant_params = sanitize_params(applicant_attributes)
        person_result = create_or_update_person(applicant_params)

        if person_result.success?
          @person = person_result.success
          @family_member = create_or_update_family_member(person, family, applicant_params)
          create_or_update_consumer_role(applicant_params, @family_member)
          create_or_update_vlp_document(applicant_params, @person)
        else
          return @person
        end

        Success([family, {family_member_id: @family_member.id, person_hbx_id: @person.hbx_id}])
      end

      def create_or_update_person(applicant_params)
        Operations::People::CreateOrUpdate.new.call(params: applicant_params)
      end

      def create_or_update_consumer_role(applicant_params, family_member)
        return unless applicant_params[:is_consumer_role]
        # assign_citizen_status
        Operations::People::CreateOrUpdateConsumerRole.new.call(params: {applicant_params: applicant_params, family_member: family_member})
      end

      def create_or_update_family_member(person, family, applicant_params)
        # TODO: Update matching family member
        family_member = family.relate_new_member(person, applicant_params[:relationship])
        family.save!
        family_member
      end

      def create_or_update_vlp_document(applicant_params, person)
        Operations::People::CreateOrUpdateVlpDocument.new.call(params: {applicant_params: applicant_params, person: person})
      end
    end
  end
end
