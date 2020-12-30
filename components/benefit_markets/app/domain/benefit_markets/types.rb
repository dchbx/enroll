# frozen_string_literal: true

require 'uri'
require 'cgi'
require 'dry-types'

Dry::Types.load_extensions(:maybe)

module Types
  send(:include, Dry.Types())
  include Dry::Logic

  # Emails              = Array.of(Types::Email)
  PositiveInteger     = Coercible::Integer.constrained(gteq: 0)
  Bson                = Types.Constructor(BSON::ObjectId) { |val| BSON::ObjectId val }
end
