# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  module FinancialAssistance
    # This class constructs financial_assistance_applicant params_hash,
    # then validates it against the ApplicantContract
    # then calls FinancialAssistance::Operations::Applicant::CreateOrUpdate
    class CreateOrUpdateApplicant
      include Dry::Monads[:result, :do]

      # @param [ FamilyMember ] family_member
      # @return [ Dry::Monads::Result::Success ] success_message
      def call(params)
        values              = yield validate(params)
        filtered_values     = yield filter(values)
        financial_applicant = yield parse_family_member(filtered_values)
        validated_applicant = yield validate_applicant_params(financial_applicant)
        result              = yield create_or_update_applicant(validated_applicant)

        Success(result)
      end

      private

      def validate(params)
        return Failure('Missing keys') unless params.key?(:family_member) || params.key?(:event)
        return Failure('Given family member is not a valid object') unless params[:family_member].is_a?(::FamilyMember)
        @event = params[:event]

        Success(params)
      end

      def filter(values)
        return Failure('Given family member is not an active object') unless values[:family_member].is_active
        return Failure('Given family member does not have a matching person') unless values[:family_member].person.present?
        return Failure('Given family member does not have a matching consumer role') unless values[:family_member].person.consumer_role.present?

        Success(values)
      end

      def parse_family_member(values)
        @family_id = values[:family_member].family.id
        member_attrs_result = ::Operations::FinancialAssistance::ParseApplicant.new.call(values)
        member_attrs_result.success? ? Success(member_attrs_result.success) : Failure(member_attrs_result.failure)
      end

      def validate_applicant_params(financial_applicant)
        contract_result = ::FinancialAssistance::Validators::ApplicantContract.new.call(financial_applicant)
        contract_result.success? ? Success(contract_result.to_h) : Failure(contract_result.errors)
      end

      def create_or_update_applicant(validated_applicant)
        ::FinancialAssistance::Operations::Applicant::CreateOrUpdate.new.call(params: validated_applicant, family_id: @family_id)
        Success('A successful call was made to FAA engine to create or update an applicant')
      end
    end
  end
end
