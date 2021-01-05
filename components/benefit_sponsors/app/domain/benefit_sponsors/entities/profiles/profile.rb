# frozen_string_literal: true

module BenefitSponsors
  module Entities
    module Profiles
      class Profile < Dry::Struct
        transform_keys(&:to_sym)

        attribute :is_benefit_sponsorship_eligible,    Types::Strict::Bool
        attribute :office_locations,                   Types::Array.of(BenefitSponsors::Entities::OfficeLocation)
      end
    end
  end
end