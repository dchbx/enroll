# frozen_string_literal: true

require 'mongo_i18n'
I18n.backend = I18n::Backend::Chain.new(I18n::Backend::KeyValue.new(MongoI18n.store), I18n.backend)

module I18n
  module Backend
    module Cache
      def _fetch(cache_key, &block)
        result = I18n.cache_store.read(cache_key)
        return result unless result.nil?
        result = catch(:exception, &block)
        I18n.cache_store.write(cache_key, result) unless result.is_a?(Proc) || result.is_a?(MissingTranslation)
        result
      end
    end
  end
end

unless ENV["NO_CACHE_TRANSLATIONS"] == "true"
  I18n::Backend::Chain.include I18n::Backend::Cache
  I18n.cache_store = ActiveSupport::Cache.lookup_store(:memory_store)
end
