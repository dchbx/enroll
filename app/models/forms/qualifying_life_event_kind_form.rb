# frozen_string_literal: true

module Forms
  class QualifyingLifeEventKindForm

    extend ActiveModel::Naming
    include ActiveModel::Conversion
    include ActiveModel::Validations
    include Virtus.model

    attribute :start_on, Date
    attribute :end_on, Date
    attribute :title, String
    attribute :tool_tip, String
    attribute :pre_event_sep_in_days, Integer
    attribute :is_self_attested, Boolean
    attribute :reason, String
    attribute :post_event_sep_in_days, Integer
    attribute :market_kind, String
    attribute :effective_on_kinds, Array[String]
    attribute :ordinal_position, Integer
    attribute :id, String

    attribute :ivl_reasons, Array[String]
    attribute :shop_reasons, Array[String]
    attribute :fehb_reasons, Array[String]
    attribute :other_reason, String

    def self.for_new(_params)
      self.new(fetch_market_reasons)
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
