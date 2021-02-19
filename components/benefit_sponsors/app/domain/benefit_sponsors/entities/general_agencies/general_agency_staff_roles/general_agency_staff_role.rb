# frozen_string_literal: true

module BenefitSponsors
  module Entities
    module GeneralAgencies
      module GeneralAgencyStaffRoles
        # Create a object with general agency staff role values
        class GeneralAgencyStaffRole < Dry::Struct
          transform_keys(&:to_sym)

          attribute :aasm_state, Types::String
          attribute :npn, Types::String
          attribute :benefit_sponsors_general_agency_profile_id, Types::Bson
        end
      end
    end
  end
end
