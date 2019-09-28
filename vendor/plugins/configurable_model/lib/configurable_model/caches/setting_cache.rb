module ConfigurableModel
  module Caches
    class SettingCache
      @@cache_prefix = "settings"

      attr_accessor :target_model

      def initialize(target_model)
        @target_model = target_model
      end

      def fetch(key)
        Rails.cache.fetch(cache_key(key)) do
          setting = target_model.find_setting(key)
          parse_value(setting) if setting.present?
        end
      end

      def read(key)
        Rails.cache.read(cache_key(key))
      end

      def write(setting)
        value = (setting.value || setting.default)
        Rails.cache.write(cache_key(setting.key), value)
      end

      private

      def cache_key(key)
        scope = [@@cache_prefix]
        scope << "#{target_model.class.name.downcase}"
        scope << target_model.id.to_s
        scope << key
        scope.join("-")
      end

      def parse_value(setting)
        value_parser = proc {|value|
          $SAFE = 2
          eval(value)
        }

        value_parser.call(setting.value || setting.default)
      end
    end
  end
end