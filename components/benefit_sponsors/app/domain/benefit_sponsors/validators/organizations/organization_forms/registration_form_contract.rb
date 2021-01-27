# frozen_string_literal: true

module BenefitSponsors
  module Validators
    module Organizations
      module OrganizationForms
        #Registration Contract is to validate submitted params for any profile (ER, GA, BR)
        class RegistrationFormContract < Dry::Validation::Contract
          params do
            optional(:person_id).maybe(:string)
            required(:profile_type).filled(:string)
            required(:staff_roles_attributes).value(:array, min_size?: 1)
            required(:organization).filled(:hash)

            before(:value_coercer) do |result|
              result_hash = result.to_h
              staff_roles = []
              if result_hash[:staff_roles_attributes].present?
                result_hash[:staff_roles_attributes].each do |_key, value|
                  staff_roles << value.to_h.deep_symbolize_keys!
                end
                result_hash[:staff_roles_attributes] = staff_roles
              end
              result_hash
            end
          end

          rule(:profile_type) do
            if key? && value
              key.failure('Invalid profile type') unless %w[benefit_sponsor broker_agency general_agency].include?(value)
            end
          end

          rule(:staff_roles_attributes).each do
            if key? && value
              result = BenefitSponsors::Validators::Organizations::OrganizationForms::StaffRoleFormContract.new.call(value.merge!(profile_type: values[:profile_type]))
              key.failure(text: "invalid staff role params", error: result.errors.to_h) if result&.failure?
            end
          end

          rule(:organization) do
            if key? && value
              result = BenefitSponsors::Validators::Organizations::OrganizationForms::OrganizationFormContract.new.call(value.merge!(profile_type: values[:profile_type]))
              key.failure(text: "invalid organization params", error: result.errors.to_h) if result&.failure?
            end
          end
        end
      end
    end
  end
end
