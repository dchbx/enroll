# frozen_string_literal: true

module BenefitSponsors
  module Entities
    module BrokerAgencies
      module BrokerAgencyStaffRoles
        # Create a object with broker agency staff role values
        class BrokerAgencyStaffRole < Dry::Struct
          transform_keys(&:to_sym)

          attribute :aasm_state, Types::String
          attribute :benefit_sponsors_broker_agency_profile_id, Types::Bson
        end
      end
    end
  end
end
