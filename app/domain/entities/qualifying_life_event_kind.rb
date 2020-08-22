# frozen_string_literal: true

module Entities
  class QualifyingLifeEventKind < Dry::Struct
    transform_keys(&:to_sym)

    attribute :start_on, Types::Date
    attribute :end_on, Types::Date.optional
    attribute :title, Types::String
    attribute :tool_tip, Types::String.optional
    attribute :pre_event_sep_in_days, Types::Integer
    attribute :is_self_attested, Types::Bool
    attribute :reason, Types::String
    attribute :post_event_sep_in_days, Types::Integer
    attribute :market_kind, Types::String
    attribute :effective_on_kinds, Types::Array.of(Types::String)
    attribute :ordinal_position, Types::Integer
    attribute :coverage_start_on, Types::Date.optional
    attribute :coverage_end_on, Types::Date.optional
    attribute :event_kind_label, Types::String
    attribute :is_visible, Types::Bool
    attribute :termination_on_kinds, Types::Array.of(Types::String).optional
    attribute :date_options_available, Types::Bool
    attribute :qle_event_date_kind, Types::String
  end
end
