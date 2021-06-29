# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  module FinancialAssistance
    # This class finds all family members associated with person
    # and will call Operations::FinancialAssistance::CreateOrUpdateApplicant
    # to update information on FinancialAssistance::Applicant objects within FAA Engine.
    class PersonCreateOrUpdateHandler
      include Dry::Monads[:result, :do]

      # @param [ Person ] person
      # @param [ String ] event_name
      # @return [ Dry::Monads::Result::Success ] success_message
      def call(params)
        values          = yield validate(params)
        filtered_values = yield filter(values)
        family_members  = yield fetch_family_members(filtered_values)
        result          = yield create_or_update_applicants(family_members)

        Success(result)
      end

      private

      def validate(params)
        return Failure('Missing params') unless params.key?(:person) || params.key?(:event)
        return Failure('Event not found') unless [:person_updated].include?(params[:event])
        return Failure('Given object is not a Person') unless params[:person].is_a?(::Person)
        @event = params[:event]
        Success(params)
      end

      def filter(values)
        values[:person].consumer_role? ? Success(values) : Failure('Cannot find ConsumerRole for given person')
      end

      def fetch_family_members(filtered_values)
        person = filtered_values[:person]
        members = person.families.inject([]) do |member_array, family|
          family_member = family.active_family_members.detect{|a_fm| a_fm.person_id == person.id}
          member_array << family_member if family_member
          member_array
        end

        members.present? ? Success(members) : Failure('No family members associated with this person')
      end

      def create_or_update_applicants(family_members)
        family_members.each do |family_member|
          ::Operations::FinancialAssistance::CreateOrUpdateApplicant.new.call({family_member: family_member, event: @event})
        rescue StandardError => e
          Rails.logger.error {"FAA Engine: Unable to do action Operations::FinancialAssistance::CreateOrUpdateApplicant for family_member with object_id: #{family_member.id} due to #{e.message}"}
        end

        Success('A successful call was made to CreateOrUpdateApplicant')
      end
    end
  end
end
