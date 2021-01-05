# frozen_string_literal: true

module BenefitSponsors
  module Entities
    module OfficeLocations
      # Entity to initialize while persisting Address record.
      class Address < Dry::Struct
        transform_keys(&:to_sym)

        attribute :kind, Types::String
        attribute :address_1, Types::String
        attribute :address_2, Types::String.optional.meta(omittable: true)
        attribute :address_3, Types::String.optional.meta(omittable: true)
        attribute :city, Types::String
        attribute :county, Types::String.optional.meta(omittable: true)
        attribute :state, Types::String
        attribute :zip, Types::String
        attribute :country_name, Types::String.optional.meta(omittable: true)
        attribute :location_state_code, Types::String.optional.meta(omittable: true)
        attribute :full_text, Types::String.optional.meta(omittable: true)
      end
    end
  end
end