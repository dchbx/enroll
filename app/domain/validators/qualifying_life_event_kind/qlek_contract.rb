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
        optional(:ordinal_position).filled(:integer)
        optional(:other_reason).maybe(:string)
        optional(:_id).maybe(:string)

        before(:value_coercer) do |result|
          other_params = {}
          other_params[:ordinal_position] = 0 if result.to_h[:ordinal_position].nil?
          other_params[:reason] = result.to_h[:other_reason] if result.to_h[:reason] == 'other'
          other_params[:reason] = (other_params[:reason] ? other_params : result.to_h)[:reason].parameterize.underscore
          result.to_h.merge(other_params)
        end
      end

      rule(:end_on, :start_on) do
        key.failure('End on must be after start on date') if values[:end_on] < values[:start_on]
      end

      rule(:pre_event_sep_in_days) do
        key.failure('Invalid Pre Event SEP( In Days )') unless value >= 0
      end

      rule(:reason) do
        reasons = ::QualifyingLifeEventKind.by_market_kind(values[:market_kind]).active_by_state.pluck(:reason).uniq
        key.failure('sep type object exists with same reason') if reasons.include?(value)
      end

      rule(:post_event_sep_in_days) do
        key.failure('Invalid Post Event SEP( In Days )') unless value >= 0
      end

      rule(:market_kind) do
        key.failure('Invalid Market Kind') unless ::QualifyingLifeEventKind::MARKET_KINDS.include?(value)
      end

      rule(:effective_on_kinds) do
        effective_on_kinds_by_market = case values[:market_kind]
                                       when 'shop'
                                         ::QualifyingLifeEventKind::SHOP_EFFECTIVE_ON_KINDS
                                       when 'individual'
                                         ::QualifyingLifeEventKind::IVL_EFFECTIVE_ON_KINDS
                                       when 'fehb'
                                         ::QualifyingLifeEventKind::FEHB_EFFECTIVE_ON_KINDS
                                       end

        key.failure('one of the selected values is invalid') if value.any? {|each_kind| !effective_on_kinds_by_market.include?(each_kind)}
      end

      rule(:ordinal_position) do
        key.failure('Invalid Ordinal Position') unless value >= 0
      end
    end
  end
end
