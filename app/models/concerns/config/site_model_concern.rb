# frozen_string_literal: true

module Config
  module SiteModelConcern
    extend ActiveSupport::Concern

    included do
      delegate :site_short_name, :to => :class
      delegate :site_key, :to => :class
      delegate :is_shop_market_enabled?, :to => :class
      delegate :is_fehb_market_enabled?, :to => :class
      delegate :is_shop_or_fehb_market_enabled?, :to => :class
      delegate :is_individual_market_enabled?, :to => :class
      delegate :is_shop_and_individual_market_enabled?, :to => :class
    end

    class_methods do
      def site_short_name
        EnrollRegistry[:enroll_app].settings(:short_name).item
      end

      def site_key
        EnrollRegistry[:enroll_app].settings(:site_key).item
      end

      def is_shop_market_enabled?
        EnrollRegistry.feature_enabled?(:aca_shop_market)
      end

      def is_fehb_market_enabled?
        EnrollRegistry.feature_enabled?(:fehb_market)
      end

      def is_shop_or_fehb_market_enabled?
        EnrollRegistry.feature_enabled?(:fehb_market) || EnrollRegistry.feature_enabled?(:aca_shop_market)
      end

      def is_individual_market_enabled?
        EnrollRegistry.feature_enabled?(:aca_individual_market)
      end

      def is_shop_and_individual_market_enabled?
        EnrollRegistry.feature_enabled?(:aca_shop_market) && EnrollRegistry.feature_enabled?(:aca_individual_market)
      end
    end
  end
end
