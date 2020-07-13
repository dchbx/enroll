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

    def self.for_new(params)
      self.new(params)
    end
  end
end
