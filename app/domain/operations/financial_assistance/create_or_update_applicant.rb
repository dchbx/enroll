# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  module FinancialAssistance
    class CreateOrUpdateApplicant
      include Dry::Monads[:result, :do]

      # on an after hook on every update of a family_member
        # Call ParseApplicant for the family member
        # Input: family_member
        # FAA Engine Call.
        # Success(application_id)
        # Success(family.active_family_members.collect {|family_member| family_member_attributes(family_member)})

      def call(params)
        values              = yield validate(params)
        financial_applicant = yield parse_family_member(values)
        result              = yield create_or_update_applicant(financial_application)

        Success(result)
      end

      private

      def validate(params)
        Failure('Given family member is not a valid object') unless params[:family_member].is_a?(::FamilyMember)
        Failure('Given family member does not have a matching person') unless params[:family_member].person.present?

        Success(params)
      end

      def parse_family_member(values)
        member_attrs_result = ::Operations::FinancialAssistance::ParseApplicant.new.call(values)
        member_attrs_result.success? ? Success(member_attrs_result.success) : Failure(member_attrs_result.failure)
      end

      def create_or_update_applicant(financial_application)
        result = ::FinancialAssistance::Operations::Applicant::CreateOrUpdate.new.call(financial_applicant: financial_applicant)
        result.success? ? Success(result.success) : Failure(result.failure)
      end
    end
  end
end
