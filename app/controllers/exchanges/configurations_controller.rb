class Exchanges::ConfigurationsController < ApplicationController
  include ::Pundit

  def edit
    respond_to do |format|
      format.js
    end
  end

  def update
    @feature = ResourceRegistry::Operations::Features::Update.new.call(feature: feature_params(params), registry: EnrollRegistry)

    respond_to do |format|
      format.js
    end
  end

  private

  def feature_params(params)
    params.require(:feature).permit(:key, :namespace, :is_enabled, settings:  {})
  end
end