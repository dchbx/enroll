# frozen_string_literal: true

module Forms
  class QualifyingLifeEventKindForm < Dry::Struct

    module Types
      include Dry::Types(default: :nominal)
    end

    extend ActiveModel::Naming
    include ActiveModel::Conversion

    attribute :start_on, Types::Date
    attribute :end_on, Types::Date
    attribute :title, Types::String
    attribute :tool_tip, Types::String
    attribute :pre_event_sep_in_days, Types::Integer
    attribute :is_self_attested, Types::Bool
    attribute :post_event_sep_in_days, Types::Integer
    attribute :market_kind, Types::String
    attribute :effective_on_kinds, Types::Array.of(Types::String)
    attribute :ordinal_position, Types::Integer.default(0)
    attribute :_id, Types::String.optional

    attribute :reason, Types::String
    attribute :other_reason, Types::String
    attribute :draft, Types::Bool

    attribute :ivl_reasons, Types::Array.of(Types::String)
    attribute :shop_reasons, Types::Array.of(Types::String)
    attribute :fehb_reasons, Types::Array.of(Types::String)


    def self.for_new(params = {})
      if params.blank?
        params = default_keys_hash
      else
        schema.each {|item| params[item.name] = nil unless params.has_key?(item.name)}
      end

      new(params.merge(fetch_market_reasons))
    end

    def self.for_edit(params)
      qlek_params = fetch_qlek_data(params[:id])
      edit_params = default_keys_hash.merge(qlek_params.symbolize_keys)
      self.new(edit_params)
    end

    def self.for_update(params)
      qlek_params = fetch_qlek_data(params[:_id]).merge(params)
      update_params = default_keys_hash.merge(qlek_params.symbolize_keys)
      self.new(update_params)
    end

    class << self
      def fetch_market_reasons
        { ivl_reasons: market_reasons('individual'),
          shop_reasons: market_reasons('shop'),
          fehb_reasons: market_reasons('fehb')}
      end

      def market_reasons(market_kind)
        reasons = "Types::#{market_kind.humanize}QleReasons".constantize.values

        reasons.inject([]) do |options_select, reason|
          options_select << [reason.titleize, reason]
        end
      end

      def fetch_qlek_data(id)
        qle = ::QualifyingLifeEventKind.find(id)
        params = qle.attributes.merge(fetch_market_reasons)
        params.merge!({draft: qle.draft?})
      end

      def default_keys_hash
        schema.inject({}) do |attribte_hash, item|
          attribte_hash[item.name] = nil
          attribte_hash
        end
      end
    end
  end
end
