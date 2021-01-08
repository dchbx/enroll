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
            required(:profile_id).filled(:string)
            required(:dob).filled(:date)
            optional(:email).maybe(:string)
          end
        end
      end
    end
  end
end
