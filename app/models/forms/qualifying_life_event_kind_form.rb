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
    attribute :ivl_reasons, Array[String]
    attribute :shop_reasons, Array[String]
    attribute :fehb_reasons, Array[String]
    attribute :other_reason, String

    attribute :id, String

    def self.for_new(params)
      form = self.new(params)
      form[:ivl_reasons] = individual_market_reasons
      form[:shop_reasons] = shop_market_reasons
      form[:fehb_reasons] = fehb_market_reasons
      form
    end

    def self.individual_market_reasons
      QualifyingLifeEventKind.individual_market_events.map(&:reason).map(&:humanize)
    end

    def self.fehb_market_reasons
      QualifyingLifeEventKind.fehb_market_events.map(&:reason).map(&:humanize)
    end

    def self.shop_market_reasons
      QualifyingLifeEventKind.shop_market_events.map(&:reason).map(&:humanize)
    end
  end
end
