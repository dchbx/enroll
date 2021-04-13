# frozen_string_literal: true

module BenefitSponsors
  module Entities
    module OfficeLocations
      # Entity to initialize while persisting OfficeLocation record.
      class OfficeLocation < Dry::Struct
        transform_keys(&:to_sym)
        include Dry::StructExtended

        attribute :is_primary,       Types::Strict::Bool.optional.meta(omittable: true)
        attribute :address,          BenefitSponsors::Entities::OfficeLocations::Address
        attribute :phone,            BenefitSponsors::Entities::OfficeLocations::Phone
      end
    end
  end
end