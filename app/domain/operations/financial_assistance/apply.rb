# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  module FinancialAssistance
    # This class constructs financial_assistance_application params_hash,
    # then validates it against the ApplicationContract
    # then calls FinancialAssistance::Operations::Application::Create
    # gets back FinancialAssistance::Application object_id
    class Apply
      include Dry::Monads[:result, :do]

      # @param [ FamilyId ] family_id bson_id of a family
      # @return [ FinancialAssistance::Application ] application_id
      def call(params)
        family_id                    = yield validate(params)
        financial_application_params = yield parse_family(family_id)
        application_id               = yield apply(financial_application_params)

        Success(application_id)
      end

      private

      def validate(params)
        if params[:family_id].is_a?(BSON::ObjectId)
          Success(params[:family_id])
        else
          Failure('family_id is expected in BSON format')
        end
      end

      def parse_family(family_id)
        family_find_result = ::Operations::Families::Find.new.call(id: family_id)
        return family_find_result if family_find_result.failure?

        family = family_find_result.success
        contract_result = ::Validators::Families::ApplicationContract.new.call(application_attributes(family))
        contract_result.success? ? Success(contract_result.to_h) : Failure(contract_result.errors)
      end

      def apply(financial_application_params)
        result = ::FinancialAssistance::Operations::Application::Create.new.call(params: financial_application_params)

        if result.success?
          Success(result.success)
        else
          Failure(result.failure)
        end
      end

      def application_attributes(family)
        application_attrs = {family_id: family.id,
                             assistance_year: family.application_applicable_year,
                             benchmark_product_id: family.benchmark_product_id,
                             is_ridp_verified: family&.primary_person&.consumer_role&.identity_verified?}

        application_attrs.merge!({applicants: applicants_attributes(family)})
        application_attrs
      end

      def applicants_attributes(family)
        family.active_family_members.inject([]) do |members_array, family_member|
          member_attrs_result = ::Operations::FinancialAssistance::ParseApplicant.new.call({family_member: family_member})
          members_array << member_attrs_result.success if member_attrs_result.success?
          members_array
        end
      end
    end
  end
end
