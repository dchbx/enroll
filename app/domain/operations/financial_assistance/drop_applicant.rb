# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  module FinancialAssistance
    # This class constructs financial_assistance_applicant params_hash,
    # then calls FinancialAssistance::Operations::Applicant::Delete
    class DropApplicant
      include Dry::Monads[:result, :do]

      # @param [ FamilyMember ] family_member
      # @return [ Dry::Monads::Result::Success ] success_message
      def call(params)
        values              = yield validate(params)
        filtered_values     = yield filter(values)
        fa_applicant_params = yield parse_family_member(filtered_values)
        result              = yield delete_applicant(fa_applicant_params)

        Success(result)
      end

      private

      def validate(params)
        return Failure('family_member key does not exist') unless params.key?(:family_member)
        return Failure('Given family member is not a valid object') unless params[:family_member].is_a?(::FamilyMember)

        Success(params)
      end

      def filter(values)
        return Failure('Given family member is an active object') if values[:family_member].is_active
        return Failure('Given family member does not have a matching person') unless values[:family_member].person.present?
        return Failure('Given family member does not have a matching consumer role') unless values[:family_member].person.consumer_role.present?

        Success(values)
      end

      def parse_family_member(values)
        @family_id = values[:family_member].family.id
        member_attrs_result = ::Operations::FinancialAssistance::ParseApplicant.new.call(values)
        member_attrs_result.success? ? Success(member_attrs_result.success) : Failure(member_attrs_result.failure)
      end

      def delete_applicant(fa_applicant_params)
        ::FinancialAssistance::Operations::Applicant::Delete.new.call({financial_applicant: fa_applicant_params, family_id: @family_id})
        Success('A successful call was made to FAA engine to delete an applicant')
      end
    end
  end
end
