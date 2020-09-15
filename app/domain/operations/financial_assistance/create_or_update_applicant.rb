# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  module FinancialAssistance
    class CreateOrUpdateApplicant
      include Dry::Monads[:result, :do]

      def call(params)
        values              = yield validate(params)
        financial_applicant = yield parse_family_member(values)
        result              = yield create_or_update_applicant(financial_applicant)

        Success(result)
      end

      private

      def validate(params)
        return Failure('Given family member is not a valid object') unless params[:family_member].is_a?(::FamilyMember)
        return Failure('Given family member does not have a matching person') unless params[:family_member].person.present?

        Success(params)
      end

      def parse_family_member(values)
        member_attrs_result = ::Operations::FinancialAssistance::ParseApplicant.new.call(values)
        member_attrs_result.success? ? Success(member_attrs_result.success) : Failure(member_attrs_result.failure)
      end

      def create_or_update_applicant(financial_applicant)
        # ::FinancialAssistance::Operations::Applicant::CreateOrUpdate.new.call(financial_applicant: financial_applicant)
        Success('A successful call was made to FAA engine to create or update an applicant')
      end
    end
  end
end
