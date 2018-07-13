module Config::SiteModelConcern
  extend ActiveSupport::Concern

  included do
    delegate :site_short_name, :to => :class
  end

  class_methods do
    def site_short_name
      Settings.site.short_name
    end
  end
end
