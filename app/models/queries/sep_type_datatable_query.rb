# frozen_string_literal: true

module Queries
  class SepTypeDatatableQuery

    attr_reader :custom_attributes

    def initialize(attributes)
      @custom_attributes = attributes
    end

    def build_scope
      qles = QualifyingLifeEventKind.all
      qles = qles.by_market_kind('individual') if @custom_attributes['manage_qles'] == 'ivl_qles'
      qles = qles.by_market_kind('shop') if @custom_attributes['manage_qles'] == 'shop_qles'
      qles = qles.by_market_kind('fehb') if @custom_attributes['manage_qles'] == 'fehb_qles'
      qles = qles.where(market_kind: 'individual', :aasm_state.in => [:active, :expired_pending]).order(ordinal_position: :asc) if @custom_attributes['individual_options'] == 'ivl_active_qles'
      qles = qles.where(market_kind: 'individual', aasm_state: :expired).order(ordinal_position: :asc) if @custom_attributes['individual_options'] == 'ivl_inactive_qles'
      qles = qles.where(market_kind: 'individual', aasm_state: :draft).order(ordinal_position: :asc) if @custom_attributes['individual_options'] == 'ivl_draft_qles'
      qles = qles.where(market_kind: 'shop', :aasm_state.in => [:active, :expired_pending]).order(ordinal_position: :asc) if @custom_attributes['employer_options'] == 'shop_active_qles'
      qles = qles.where(market_kind: 'shop', aasm_state: :expired).order(ordinal_position: :asc) if @custom_attributes['employer_options'] == 'shop_inactive_qles'
      qles = qles.where(market_kind: 'shop', aasm_state: :draft).order(ordinal_position: :asc) if @custom_attributes['employer_options'] == 'shop_draft_qles'
      qles = qles.where(market_kind: 'fehb', :aasm_state.in => [:active, :expired_pending]).order(ordinal_position: :asc) if @custom_attributes['congress_options'] == 'fehb_active_qles'
      qles = qles.where(market_kind: 'fehb', aasm_state: :expired).order(ordinal_position: :asc) if @custom_attributes['congress_options'] == 'fehb_inactive_qles'
      qles = qles.where(market_kind: 'fehb', aasm_state: :draft).order(ordinal_position: :asc) if @custom_attributes['congress_options'] == 'fehb_draft_qles'
      qles
    end

    def skip(num)
      build_scope.skip(num)
    end

    def limit(num)
      build_scope.limit(num)
    end

    def order_by(var)
      @order_by = var
      self
    end

    def klass
      QualifyingLifeEventKind
    end

    def size
      build_scope.count
    end
  end
end
