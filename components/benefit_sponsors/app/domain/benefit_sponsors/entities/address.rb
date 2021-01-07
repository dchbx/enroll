# frozen_string_literal: true

module BenefitSponsors
  module Entities
    class Address < Dry::Struct
      transform_keys(&:to_sym)

      attribute :kind, Types::String.optional
      attribute :address_1, Types::String.optional
      attribute :address_2, Types::String.optional.meta(omittable: true)
      attribute :address_3, Types::String.optional.meta(omittable: true)
      attribute :city, Types::String.optional
      attribute :county, Types::String.optional.meta(omittable: true)
      attribute :state, Types::String.optional
      attribute :zip, Types::String.optional
      attribute :country_name, Types::String.optional.meta(omittable: true)

    end
  end
end
