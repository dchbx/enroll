# frozen_string_literal: true

module Entities
  module People
    module Roles
      class Role < Dry::Struct
        transform_keys(&:to_sym)

        attribute :name,    Types::String
        attribute :link,    Types::String.optional.meta(omittable: true)
        attribute :kind,    Types::String
        attribute :date,    Types::Date.optional.meta(omittable: true)
        attribute :status,  Types::Symbol
      end
    end
  end
end