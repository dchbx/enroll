# frozen_string_literal: true

module BenefitSponsors
  module Entities
    module OfficeLocations
      # Entity to initialize while persisting Phone record.
      class Phone < Dry::Struct
        transform_keys(&:to_sym)

        attribute :kind, Types::String.optional
        attribute :country_code, Types::String.optional.meta(omittable: true)
        attribute :area_code, Types::String.optional.meta(omittable: true)
        attribute :number, Types::String.optional.meta(omittable: true)
        attribute :extension, Types::String.optional.meta(omittable: true)
        attribute :full_phone_number, Types::String.optional.meta(omittable: true)
        attribute :primary, Types::Bool.optional.meta(omittable: true)
      end
    end
  end
end