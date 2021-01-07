# frozen_string_literal: true

module BenefitSponsors
  module Validators
    module BrokerAgencies
      module BrokerAgencyStaffRoles
        # Staff Contract is to validate broker staff role record
        class BrokerStaffRoleContract < Dry::Validation::Contract
          params do
            required(:aasm_state).filled(:string)
            required(:benefit_sponsors_broker_agency_profile_id).filled(Types::Bson)
          end
        end
      end
    end
  end
end
