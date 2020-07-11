# frozen_string_literal: true

module Validators
  module QualifyingLifeEventKind
    class QlekContract < ::Dry::Validation::Contract

      params do
        required(:start_on).filled(:date)
        required(:end_on).filled(:date)
        required(:title).filled(:string)
        required(:tool_tip).filled(:string)
        required(:pre_event_sep_in_days).filled(:integer)
        required(:is_self_attested).filled(:bool)
        required(:reason).filled(:string)
        required(:post_event_sep_in_days).filled(:integer)
        required(:market_kind).filled(:string)
        required(:effective_on_kinds).array(:string)
        required(:ordinal_position).filled(:integer)
      end

      rule(:pre_event_sep_in_days) do
        key.failure('Invalid Pre Event SEP( In Days )') unless value > 0
      end

      rule(:post_event_sep_in_days) do
        key.failure('Invalid Post Event SEP( In Days )') unless value > 0
      end

      rule(:market_kind) do
        key.failure('Invalid Market Kind') unless ::QualifyingLifeEventKind::MARKET_KINDS.include?(value)
      end

      rule(:ordinal_position) do
        key.failure('Invalid Ordinal Position') unless value > 0
      end

      rule(:end_on, :start_on) do
        key.failure('End on must be after start on date') if values[:end_on] < values[:start_on]
      end

    end
  end
end
