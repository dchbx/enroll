# frozen_string_literal: true

module BenefitSponsors
  module Entities
    module Profiles
      # Entity acts a top level profile class
      class Profile < Dry::Struct
        attribute :contact_method,                     Types::Strict::Symbol
        attribute :office_locations,                   Types::Array.of(BenefitSponsors::Entities::OfficeLocations::OfficeLocation)
      end
    end
  end
end