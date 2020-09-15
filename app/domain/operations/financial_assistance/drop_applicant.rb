# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  module FinancialAssistance
    class DropApplicant
      include Dry::Monads[:result, :do]

      # Input: family_member
      # Output: Dry::Monads::Result::Success
      def call(params)
        values              = yield validate(params)
        fa_applicant_params = yield parse_family_member(values)
        result              = yield delete_applicant(fa_applicant_params)

        Success(result)
      end

      private

      def validate(params)
        return Failure('family_member key does not exist') unless params.key?(:family_member)
        return Failure('Given family member is not a valid object') unless params[:family_member].is_a?(::FamilyMember)
        return Failure('Given family member is an active object') if params[:family_member].is_active
        return Failure('Given family member does not have a matching person') unless params[:family_member].person.present?

        Success(params)
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
