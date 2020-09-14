# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  module FinancialAssistance
    class Apply
      include Dry::Monads[:result, :do]

      # This operation will take family_id
        # Call FAA Engine to create Application and Applicants matching FamilyMembers
      # Build application_data from family object
      # Call ParseApplicant for each family member.
      # assistance_year + years_to_renew = renewal_consent_through_year
      # FAA Engine Call.
      # Sucess(application_id)
      # Success(family.active_family_members.collect {|family_member| family_member_attributes(family_member)})

      def call(params)
        values                       = yield validate(params)
        financial_application_params = yield parse_family(values)
        application_id               = yield apply(financial_application_params)

        Success(application_id)
      end

      private

      def validate(params)
        params[:family_id].present? ? Success(params) : Failure('family_id value does not exist')
      end

      def parse_family(params)
        family_find_result = ::Operations::Families::Find.new.call(values[:family_id])
        return family_find_result if family_find_result.failure?
        @family = family_find_result.success
        contract_result = ::Validators::Families::ApplicationContract.new.call(application_attributes(@family))
        contract_result.success?? Success(contract_result.success) : Failure(contract_result.failure)
      end

      def apply(financial_application_params)
        result = ::FinancialAssistance::Operations::Application::Create.new.call(params: financial_application_params)
        result.success? ? Success(result.success) : Failure(result.failure)
      end

      def application_attributes(family)
        application_attrs = {family_id: family.id,
                             assistance_year: family.application_applicable_year,
                             years_to_renew: family.renewal_consent_through_year,
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
