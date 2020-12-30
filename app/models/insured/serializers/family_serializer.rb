# frozen_string_literal: true

module Insured
  module Serializers
    class FamilySerializer < ::ActiveModel::Serializer

      attribute :id
      attribute :is_under_ivl_oe
      attribute :qle_kind_id,  if: :latest_active_sep_present?
      attribute :sep_id, if: :latest_active_sep_present?

      delegate :id, to: :object

      def is_under_ivl_oe
        object.is_under_ivl_open_enrollment?
      end

      def latest_active_sep_present?
        object.latest_active_sep.present?
      end

      def qle_kind_id
        object.latest_active_sep.qualifying_life_event_kind_id
      end

      def sep_id
        object.latest_active_sep.id
      end

      # provide defaults(if any needed) that were not set on Model
      def attributes(*args)
        hash = super
        unless object.persisted?

        end
        hash
      end
    end
  end
end
