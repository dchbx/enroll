# frozen_string_literal: true

module BenefitSponsors
  module Entities
    module Forms
      module GeneralAgencies
        module GeneralAgencyStaffRoles
          # Entity to initialize while showing general agency staff staff record.
          class New < Dry::Struct
            transform_keys(&:to_sym)

            attribute :person_id,            Types::String
            attribute :first_name,           Types::String
            attribute :last_name,            Types::String
            attribute :dob,                  Types::Date.meta(omittable: true)
            attribute :email,                Types::String.optional.meta(omittable: true)
          end
        end
      end
    end
  end
end
