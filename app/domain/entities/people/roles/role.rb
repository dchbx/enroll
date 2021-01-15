# frozen_string_literal: true

module Entities
  module People
    module Roles
      # Role entity holds information about role model.
      # We use this entity to build forms in UI
      class Role < Dry::Struct
        transform_keys(&:to_sym)

        attribute :name,        Types::String
        attribute :link,        Types::String.optional.meta(omittable: true)
        attribute :kind,        Types::String
        attribute :date,        Types::Date.optional.meta(omittable: true)
        attribute :status,      Types::Symbol
        attribute :description, Types::String.optional.meta(omittable: true)
      end
    end
  end
end