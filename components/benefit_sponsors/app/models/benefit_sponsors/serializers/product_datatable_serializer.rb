# frozen_string_literal: true

module BenefitSponsors
  module Serializers
    class ProductDatatableSerializer
      include FastJsonapi::ObjectSerializer

      attributes :name, :active_year, :hios_id

      attribute :benefit_market_kind do |object|
        case object.benefit_market_kind
        when :aca_individual then 'Individual'
        when :aca_shop then 'Shop'
        when :fehb then 'Congressional'
        end
      end

      attribute :kind do |object|
        case object.kind
        when :health then 'Health'
        when :dental then 'Dental'
        end
      end

      attribute :size do
        ''
      end
    end
  end
end
