# frozen_string_literal: true

module BenefitSponsors
  module Validators
    module GeneralAgencies
      module GeneralAgencyStaffRoles
        # Staff Contract is to validate general agency staff role record
        class GeneralAgencyStaffRoleContract < Dry::Validation::Contract
          params do
            required(:aasm_state).filled(:string)
            required(:npn).filled(:string)
            required(:benefit_sponsors_general_agency_profile_id).filled(Types::Bson)
          end
        end
      end
    end
  end
end
