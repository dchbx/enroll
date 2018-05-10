require 'mongo_i18n'
I18n.backend = I18n::Backend::Chain.new(I18n::Backend::KeyValue.new(MongoI18n.store), I18n.backend)
if Rails.env.production?
  I18n::Backend::KeyValue.send(:include, I18n::Backend::Cache)
  I18n.cache_store = ActiveSupport::Cache.lookup_store(:memory_store)
end
