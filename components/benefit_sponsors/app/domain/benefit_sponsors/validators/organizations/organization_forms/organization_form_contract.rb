# frozen_string_literal: true

module BenefitSponsors
  module Validators
    module Organizations
      module OrganizationForms
        #Contract is to validate submitted params for organization creation
        class OrganizationFormContract < Dry::Validation::Contract

          params do
            required(:profile_type).filled(:string)
            required(:legal_name).filled(:string)
            required(:entity_kind).filled(:symbol)
            optional(:fein).maybe(:string)
            optional(:dba).maybe(:string)
            required(:profile).filled(:hash)
          end

          rule(:fein) do
            key.failure('Please enter FEIN') if key? && values[:profile_type] != 'broker_agency' && value.blank?
          end

          rule(:profile) do
            if key? && value
              result = BenefitSponsors::Validators::Organizations::OrganizationForms::ProfileFormContract.new.call(value.merge!(profile_type: values[:profile_type]))
              key.failure(text: "invalid profile params", error: result.errors.to_h) if result&.failure?
            end
          end
        end
      end
    end
  end
end
