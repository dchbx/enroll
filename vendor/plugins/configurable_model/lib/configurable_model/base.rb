module ConfigurableModel
  module Base

    def [](key)
      setting_cache.fetch(key)
    end

    def []=(key, attrs)
      find_or_initialize_setting(key).tap do |setting|
        setting.attributes = attrs
        setting.save!
        setting_cache.write(setting)
      end
    end

    def find_or_initialize_setting(key)
      find_setting(key) || settings.new(key: key)
    end

    def find_setting(key)
      settings.by_key(key).first
    end

    def import_settings(settings)
      config = Options.new
      config.configurable_obj = self
      config.add_source!(settings)
      config.load!
    end

    def setting_cache
      Caches::SettingCache.new(self)
    end

    def settings
      eval("#{self.class.to_s.demodulize.underscore}_settings")
    end
  end
end