# frozen_string_literal: true

module BenefitSponsors
  module Validators
    module Registrations
      # Agency Registration Contract is to validate submitted params while persisting Agency Registration
      class AgencyRegistrationContract < Dry::Validation::Contract
        params do
          required(:profile_type).filled(:string)
          required(:staff_roles).filled(:hash)
          required(:organization).filled(:hash)
        end

        rule(:staff_roles) do
          if key? && value
            result = BenefitSponsors::Validators::StaffRoles::AgencyStaffRoleContract.new.call(value)
            key.failure(text: "invalid staff roles", error: result.errors.to_h) if result&.failure?
          end
        end

        rule(:organization) do
          if key? && value
            if values[:profile_type] == 'broker_agency'
              result = BenefitSponsors::Validators::Organizations::ExemptOrganizationContract.new.call(value)
              key.failure(text: "invalid broker agency organization", error: result.errors.to_h) if result&.failure?
            else
              result = BenefitSponsors::Validators::Organizations::GeneralOrganizationContract.new.call(value)
              key.failure(text: "invalid general agency organization", error: result.errors.to_h) if result&.failure?
            end
          end
        end
      end
    end
  end
end
