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
    attribute :coverage_effective_on, Types::Date
    attribute :coverage_end_on, Types::Date
    attribute :event_kind_label, Types::String
    attribute :is_visible, Types::Bool
    attribute :termination_on_kinds, Types::Array.of(Types::String)
    attribute :date_options_available, Types::Bool
    attribute :reason, Types::String
    attribute :draft, Types::Bool
    attribute :ivl_effective_kinds, Types::Array.of(Types::String)
    attribute :shop_effective_kinds, Types::Array.of(Types::String)
    attribute :fehb_effective_kinds, Types::Array.of(Types::String)

    def self.for_new(params = {})
      if params.blank?
        params = default_keys_hash
      else
        schema.each {|item| params[item.name] = nil unless params.key?(item.name)}
      end

      new(params.merge(fetch_additional_params))
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

    class << self
      def fetch_additional_params
        { ivl_effective_kinds: ::Types::IndividualEffectiveOnKinds.values,
          shop_effective_kinds: ::Types::ShopEffectiveOnKinds.values,
          fehb_effective_kinds: ::Types::FehbEffectiveOnKinds.values }
      end

      def fetch_qlek_data(id, update_params = nil)
        qle = ::QualifyingLifeEventKind.find(id)
        params = if update_params.present?
                   update_params.merge(fetch_additional_params)
                 else
                   qle.attributes.merge(fetch_additional_params)
                 end
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
