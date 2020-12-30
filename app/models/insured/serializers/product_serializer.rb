# frozen_string_literal: true

module Insured
  module Serializers
    class ProductSerializer < ::ActiveModel::Serializer
      attributes :id, :active_year, :display_carrier_logo, :nationwide, :application_period, :title, :hios_id, :issuer_profile_id, :metal_level_kind, :kind

      def display_carrier_logo(options = {:width => 50})
        carrier_name = object.find_carrier_info
        "<img src=\"\/assets\/logo\/carrier\/#{carrier_name.parameterize.underscore}.jpg\" width=\"#{options[:width]}\"/>"
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
