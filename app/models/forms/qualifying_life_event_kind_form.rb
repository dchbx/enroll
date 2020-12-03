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
    attribute :coverage_start_on, Types::Date
    attribute :coverage_end_on, Types::Date
    attribute :event_kind_label, Types::String
    attribute :qle_event_date_kind, Types::String
    attribute :is_visible, Types::Bool
    attribute :termination_on_kinds, Types::Array.of(Types::String)
    attribute :date_options_available, Types::Bool
    attribute :reason, Types::String
    attribute :draft, Types::Bool
    attribute :other_reason, Types::String
    attribute :qlek_reasons, Types::Array.of(Types::String)
    attribute :updated_by, Types::String
    attribute :created_by, Types::String
    attribute :published_by, Types::String

    def self.for_new(params = {})
      if params.blank?
        params = default_keys_hash
      else
        schema.each {|item| params[item.name] = nil unless params.key?(item.name)}
      end
      set_params(params)

      new params
    end

    def self.for_edit(params)
      self.params(fetch_qlek_data(params[:id]))
    end

    def self.for_clone(params)
      self.params(fetch_qlek_data(params[:id]).except(:_id, :start_on, :end_on, :ordinal_position))
    end

    def self.for_update(params)
      self.params(fetch_qlek_data(params[:_id], params))
    end

    def self.params(qlek_params)
      self.new(default_keys_hash.merge(qlek_params.symbolize_keys))
    end

    def qle_kind_reason_options
      (QualifyingLifeEventKind::REASON_KINDS + QualifyingLifeEventKind.non_draft.map(&:reason).uniq)
    end

    class << self
      def fetch_qlek_data(id, update_params = nil)
        qle = ::QualifyingLifeEventKind.find(id)
        params = if update_params.present?
                   update_params
                 else
                   qle.attributes
                 end
        set_params(params, qle)
        params
      end

      def set_params(params, qle = nil)
        params[:reason] = 'other' if params[:other_reason]
        params[:qlek_reasons] = ::Types::QLEKREASONS.values
        params[:draft] = qle.draft? if qle
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
