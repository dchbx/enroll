# frozen_string_literal: true

module BenefitSponsors
  module Validators
    module GeneralAgencies
      module GeneralAgencyStaffRoles
        # Staff Contract is to validate submitted params while persisting staff
        class AddGeneralAgencyStaffRoleContract < Dry::Validation::Contract

          params do
            required(:person_id).value(:string)
            required(:first_name).value(:string)
            required(:last_name).value(:string)
            required(:profile_id).value(:string)
            required(:dob).maybe(:date)
            optional(:email).maybe(:string)
          end
        end
      end
    end
  end
end
