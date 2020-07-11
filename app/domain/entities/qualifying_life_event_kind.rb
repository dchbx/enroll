# frozen_string_literal: true

module Entities
  class QualifyingLifeEventKind < Dry::Struct
    transform_keys(&:to_sym)

    attribute :start_on, Types::Date
    attribute :end_on, Types::Date
    attribute :title, Types::String
    attribute :tool_tip, Types::String
    attribute :pre_event_sep_in_days, Types::Integer
    attribute :is_self_attested, Types::Bool
    attribute :reason, Types::String
    attribute :post_event_sep_in_days, Types::Integer
    attribute :market_kind, Types::String
    attribute :effective_on_kinds, Types::Array.of(Types::String)
    attribute :ordinal_position, Types::Integer
  end
end
