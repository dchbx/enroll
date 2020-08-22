# frozen_string_literal: true

module ResourceRegistryWorld
  def enable_feature(feature_name)
    return if feature_enabled?(feature_name)

    feature_dsl = EnrollRegistry[feature_name]
    feature_dsl.feature.stub(:is_enabled).and_return(true)
  end

  def disable_feature(feature_name)
    return unless feature_enabled?(feature_name)

    feature_dsl = EnrollRegistry[feature_name]
    feature_dsl.feature.stub(:is_enabled).and_return(false)
  end

  def feature_enabled?(feature_name)
    EnrollRegistry.feature_enabled?(feature_name)
  end
end

World(ResourceRegistryWorld)
