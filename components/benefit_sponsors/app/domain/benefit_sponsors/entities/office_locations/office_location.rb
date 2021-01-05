# frozen_string_literal: true

module BenefitSponsors
  module Entities
    module OfficeLocations
      class OfficeLocation < Dry::Struct
        transform_keys(&:to_sym)

        attribute :is_primary,       Types::Strict::Bool
        attribute :address,          BenefitSponsors::Entities::OfficeLocations::Address
        attribute :phone,            BenefitSponsors::Entities::OfficeLocations::Phone
      end
    end
  end
end