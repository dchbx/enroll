require 'configurable_model/version'
require 'configurable_model/base'
require 'configurable_model/relation'
require 'configurable_model/setting'
require 'configurable_model/options'
require 'configurable_model/sources/hash_source'
require 'configurable_model/caches/setting_cache'

module ConfigurableModel
  extend ActiveSupport::Concern
  include ConfigurableModel::Base

  included do
    relation = ConfigurableModel::Relation.new(self)

    Class.new do
      include ConfigurableModel::Setting
      store_in collection: relation.setting_collection.downcase

      belongs_to relation.base_relation.to_sym, class_name: relation.base_klass,
        inverse_of: relation.setting_relation.to_sym
    end.tap do |klass|
      relation.base_klass_name_space.constantize.const_set(relation.setting_klass, klass)
    end

    has_many relation.setting_relation.to_sym, class_name: relation.setting_klass_with_module
  end
end





