# frozen_string_literal: true

module BenefitMarkets
  module Forms
    class ProductForm
      include Virtus.model
      include ActiveModel::Model

      attribute :is_late_rate
      attribute :date

      def factory(param)
        @factory = ::BenefitMarkets::Products::ProductFactory.new({date: param})
      end

      def self.for_new(param)
        self.new(:date => param)
      end

      def fetch_results
        new_product_factory = factory(date)
        self.is_late_rate = !new_product_factory.has_rates?
        self
      end
    end
  end
end