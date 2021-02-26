# frozen_string_literal: true

module Validators
  module QualifyingLifeEventKind
    class QlekContract < ::Dry::Validation::Contract
      params do
        required(:start_on).filled(:date)
        optional(:end_on).maybe(:date)
        required(:title).filled(:string)
        optional(:tool_tip).maybe(:string)
        required(:pre_event_sep_in_days).filled(:integer)
        required(:is_self_attested).filled(:bool)
        required(:reason).filled(:string)
        required(:post_event_sep_in_days).filled(:integer)
        required(:market_kind).filled(:string)
        required(:effective_on_kinds).array(:string)
        optional(:ordinal_position).filled(:integer)
        optional(:_id).maybe(:string)
        optional(:coverage_start_on).maybe(:date)
        optional(:coverage_end_on).maybe(:date)
        required(:event_kind_label).filled(:string)
        required(:is_visible).filled(:bool)
        optional(:termination_on_kinds).maybe(:array)
        required(:date_options_available).filled(:bool)
        optional(:publish).maybe(:string)
        required(:qle_event_date_kind).maybe(:string)
        optional(:other_reason).maybe(:string)
        optional(:updated_by).maybe(:string)
        optional(:published_by).maybe(:string)
        optional(:created_by).maybe(:string)

        before(:value_coercer) do |result|
          result_hash = result.to_h
          other_params = {}
          other_params[:ordinal_position] = 0 if result_hash[:ordinal_position].nil?
          result_hash[:reason] = "" if result_hash[:reason] == 'Choose...'
          other_params[:reason] = result_hash[:other_reason].parameterize.underscore if result_hash[:reason] == 'other'
          other_params[:reason] = (other_params[:reason] ? other_params : result_hash)[:reason]
          other_params[:termination_on_kinds] = [] if result_hash[:market_kind].to_s == 'individual' || result_hash[:termination_on_kinds].nil?
          other_params[:published_by] = '' if result_hash[:publish] != 'Publish'
          other_params[:updated_by] = ''
          result_hash.merge(other_params)
        end
      end

      rule(:start_on) do
        key.failure(I18n.t("validators.qualifying_life_event_kind.start_date_valid")) if values[:start_on].present? && values[:start_on].is_a?(Date) && values[:start_on] < TimeKeeper.date_of_record
      end

      rule(:end_on, :start_on) do
        if values[:end_on].present?
          key.failure(I18n.t("validators.qualifying_life_event_kind.date")) unless values[:end_on].is_a?(Date)
          key.failure(I18n.t("validators.qualifying_life_event_kind.end_date_valid")) if values[:end_on].is_a?(Date) && values[:end_on] < values[:start_on]
        end
      end

      rule(:pre_event_sep_in_days) do
        key.failure(I18n.t("validators.qualifying_life_event_kind.pre_event_sep_in_days")) unless value >= 0
      end

      rule(:title) do
        if values[:publish].present? && values[:publish] == 'Publish'
          titles = ::QualifyingLifeEventKind.by_market_kind(values[:market_kind]).by_date(values[:start_on]).active_by_state.pluck(:title).map(&:parameterize).uniq
          key.failure(I18n.t("validators.qualifying_life_event_kind.title")) if titles.include?(value.parameterize)
        end
      end

      rule(:post_event_sep_in_days) do
        key.failure(I18n.t("validators.qualifying_life_event_kind.post_event_sep_in_days")) unless value >= 0
      end

      rule(:market_kind) do
        key.failure(I18n.t("validators.qualifying_life_event_kind.market_kind")) unless ::QualifyingLifeEventKind::MARKET_KINDS.include?(value)
      end

      rule(:effective_on_kinds) do
        key.failure(I18n.t("validators.qualifying_life_event_kind.effective_on_kinds")) if values[:effective_on_kinds].blank?
      end

      rule(:ordinal_position) do
        key.failure(I18n.t("validators.qualifying_life_event_kind.ordinal_position")) unless value >= 0
      end

      rule(:coverage_start_on) do
        key.failure(I18n.t("validators.qualifying_life_event_kind.date")) if values[:coverage_start_on].present? && !values[:coverage_start_on].is_a?(Date)

        key.failure(I18n.t("validators.qualifying_life_event_kind.coverage_start_on")) if values[:coverage_start_on].blank? && values[:coverage_end_on].present? && values[:coverage_end_on].is_a?(Date)
      end

      rule(:coverage_end_on) do
        key.failure(I18n.t("validators.qualifying_life_event_kind.date")) if values[:coverage_end_on].present? && !values[:coverage_end_on].is_a?(Date)

        key.failure(I18n.t("validators.qualifying_life_event_kind.coverage_end_on")) if values[:coverage_start_on].present? && values[:coverage_end_on].blank? && values[:coverage_start_on].is_a?(Date)

        if values[:coverage_start_on].present? && values[:coverage_end_on].present? && values[:coverage_start_on].is_a?(Date) && values[:coverage_end_on].is_a?(Date) && (values[:coverage_end_on] <= values[:coverage_start_on])
          key.failure(I18n.t("validators.qualifying_life_event_kind.coverage_end_on_valid"))
        end
      end

      rule(:termination_on_kinds) do
        #TODO: uncomment when required mandatory for shop market
        #key.failure('must be selected') if values[:market_kind] != 'individual' && values[:termination_on_kinds].blank?

        key.failure(I18n.t("validators.qualifying_life_event_kind.termination_on_kind")) if values[:termination_on_kinds].present? && values[:termination_on_kinds].any? {|ele| !ele.is_a?(String)}
      end
    end
  end
end
