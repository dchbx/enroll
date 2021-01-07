# frozen_string_literal: true

module BenefitSponsors
  module Validators
    module BrokerAgencies
      module BrokerAgencyStaffRoles
        # Staff Contract is to validate submitted params while persisting staff
        class AddBrokerStaffRoleContract < Dry::Validation::Contract

          params do
            required(:person_id).value(:string)
            required(:first_name).value(:string)
            required(:last_name).value(:string)
            optional(:profile_id).value(:string)
            optional(:dob).maybe(:date)
            optional(:email).maybe(:string)
          end
        end
      end
    end
  end
end
