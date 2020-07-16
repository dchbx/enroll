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
    attribute :id, Types::String.optional

    attribute :reason, Types::String
    attribute :other_reason, Types::String

    attribute :ivl_reasons, Types::Array.of(Types::String)
    attribute :shop_reasons, Types::Array.of(Types::String)
    attribute :fehb_reasons, Types::Array.of(Types::String)


    def self.for_new(params = {})
      if params.blank?
        params = schema.inject({}) {|hash, item| hash[item.name]= nil; hash}
      else
        schema.each {|item| params[item.name] = nil unless params.has_key?(item.name)}
      end

      new(params.merge(fetch_market_reasons))
    end

    class << self
      def fetch_market_reasons
        { ivl_reasons: market_reasons('individual'),
          shop_reasons: market_reasons('shop'),
          fehb_reasons: market_reasons('fehb')}
      end

      def market_reasons(market_kind)
        QualifyingLifeEventKind.send("#{market_kind}_market_events").map(&:reason).uniq.inject([]) do |options_select, reason|
          options_select << [reason.titleize, reason]
        end
      end
    end
  end
end
