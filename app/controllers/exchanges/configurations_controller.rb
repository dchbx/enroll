class Exchanges::ConfigurationsController < ApplicationController
  include ::Pundit

  def edit
    @filter_result = EnrollRegistry[params[:id]] {params[:filter]}.success if params[:filter]

    respond_to do |format|
      format.js
    end
  end

  def namespace_edit
    namespace = EnrollRegistry[params[:id]].namespace.split('.').map(&:to_sym)
    @namespace = ResourceRegistry::Operations::Namespaces::Form.new.call(namespace: namespace, registry: EnrollRegistry).success

    respond_to do |format|
      format.js
    end
  end

  def renew_feature
    @result = EnrollRegistry[params[:id]] {{params: params[:feature], registry: EnrollRegistry}}

    respond_to do |format|
      format.js
    end
  end

  def update_feature
    @feature = ResourceRegistry::Operations::Features::Update.new.call(feature: feature_params, registry: EnrollRegistry, filter: params[:filter])

    respond_to do |format|
      format.js
    end
  end

  def update_namespace
    @path = params[:namespace][:path]
    @result = ResourceRegistry::Operations::Namespaces::UpdateFeatures.new.call(namespace: params.require(:namespace), registry: EnrollRegistry)

    respond_to do |format|
      format.js
    end
  end

  def toggle_feature
    @feature = ResourceRegistry::Operations::Features::Update.new.call(feature: toggle_feature_params, registry: EnrollRegistry)
  end

  private

  def feature_params
    params.require(:feature).permit(:key, :namespace, :is_enabled, settings:  {})
  end

  def toggle_feature_params
    {key: params[:id], toggle_feature: true, is_enabled: params[:is_enabled]}
  end
end