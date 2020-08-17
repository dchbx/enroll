# frozen_string_literal: true

module ResourceRegistryWorld
  def enable_feature(feature_name)
    return if EnrollRegistry.feature_enabled?(feature_name)

    feature_dsl = EnrollRegistry[feature_name]
    feature_dsl.feature.stub(:is_enabled).and_return(true)
  end

  def disable_feature(feature_name)
    return unless EnrollRegistry.feature_enabled?(feature_name)

    feature_dsl = EnrollRegistry[feature_name]
    feature_dsl.feature.stub(:is_enabled).and_return(false)
  end
end

World(ResourceRegistryWorld)
