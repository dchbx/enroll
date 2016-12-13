class Exchanges::HbxSettingsController < ApplicationController
  layout 'application'

  def show
    if File.exists?(settings_file)
      @current_settings = YAML.load(File.read(settings_file))
    else
      # Initialize (seed file?)
    end

    respond_to do |format|
      format.html { @current_settings }
      format.js {}
    end
  end

  def edit
    if File.exists?(settings_file)
      @current_settings = YAML.load(File.read(settings_file))
    else
      # Initialize (seed file?)
    end

    respond_to do |format|
      format.html { @current_settings }
      format.js {}
    end
  end

  def update
    # @updated_settings = [:params]
    raise "made it!"
    # File.write(settings_file, @updated_settings)
  end

private

  def settings_file
    File.expand_path(Rails.root + 'config/settings.yml', __FILE__)
  end

end
