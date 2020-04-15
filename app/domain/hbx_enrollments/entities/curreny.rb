# frozen_string_literal: true

require 'dry-struct'

module HbxEnrollments
  module Entities
    class Curreny < Dry::Struct

      transform_keys(&:to_sym)

      attribute :cents,              Types::Strict::Float.default(0.0)
      attribute :currency_iso,       Types::Strict::String.default("USD")
    end
  end
end

