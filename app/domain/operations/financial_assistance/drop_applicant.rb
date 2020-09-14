# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  module FinancialAssistance
    class DropApplicant
      include Dry::Monads[:result, :do]

      # This is called when we soft delete
      def call(params:)
        # Input: family_member
        values              = yield validate(params)
        financial_applicant = yield parse_family_member(values)
        result              = yield delete_applicant(financial_application)

        Success(result)
      end

      private

      def validate(params)
        Failure('Given family member is not a valid object') unless params[:family_member].is_a?(::FamilyMember)
        Failure('Given family member is an active object') if params[:family_member].is_active
        Failure('Given family member does not have a matching person') unless params[:family_member].person.present?

        Success(params)

        # check the class.
        # check the field is_active is false.
        # check if the object is persisted.
      end

      def parse_family_member(values)
        member_attrs_result = ::Operations::FinancialAssistance::ParseApplicant.new.call(values)
        member_attrs_result.success? ? Success(member_attrs_result.success) : Failure(member_attrs_result.failure)
      end

      def create_or_update_applicant(financial_application)
        # FAA Engine Call.
        result = ::FinancialAssistance::Operations::Applicant::Delete.new.call({financial_applicant: financial_applicant})
        result.success? ? Success(result.success) : Failure(result.failure)
      end
    end
  end
end
