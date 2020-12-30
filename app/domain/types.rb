# frozen_string_literal: true

require 'cgi'
require 'dry-types'

Dry::Types.load_extensions(:maybe)

module Types
  send(:include, Dry.Types())
  include Dry::Logic

  REASONS = QualifyingLifeEventKind.non_draft.map(&:reason).uniq
  QLEKREASONS = Types::Coercible::String.enum(*REASONS)
end