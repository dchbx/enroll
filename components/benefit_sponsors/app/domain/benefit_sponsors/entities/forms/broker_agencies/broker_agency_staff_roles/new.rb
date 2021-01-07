# frozen_string_literal: true

module BenefitSponsors
  module Entities
    module Forms
      module BrokerAgencies
        module BrokerAgencyStaffRoles
          # Entity to initialize while showing broker staff record.
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
