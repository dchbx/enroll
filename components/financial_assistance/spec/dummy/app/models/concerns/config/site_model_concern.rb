# frozen_string_literal: true

module Config
  module SiteModelConcern
    extend ActiveSupport::Concern

    included do
      delegate :site_short_name, :to => :class
      delegate :site_key, :to => :class
    end

    class_methods do
      def site_short_name
        Settings.site.short_name
      end

      def site_key
        Settings.site.key
      end
    end
  end
end
