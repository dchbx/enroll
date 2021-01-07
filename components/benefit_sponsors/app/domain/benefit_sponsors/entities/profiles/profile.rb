# frozen_string_literal: true

module BenefitSponsors
  module Entities
    module Profiles
      # Entity acts a top level profile class
      class Profile < Dry::Struct
        transform_keys(&:to_sym)

        attribute :is_benefit_sponsorship_eligible,    Types::Strict::Bool
        attribute :contact_method,                     Types::Strict::Symbol
        attribute :office_locations,                   Types::Array.of(BenefitSponsors::Entities::OfficeLocations::OfficeLocation)
      end
    end
  end
end