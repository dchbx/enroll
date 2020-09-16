# frozen_string_literal: true

require_relative 'boot'

require "rails"
require "action_controller/railtie"
require "action_mailer/railtie"
require "action_view/railtie"
require "sprockets/railtie"

Bundler.require(*Rails.groups)
require "devise"
require 'resource_registry'
require "financial_assistance"
require "symmetric-encryption"

module Dummy
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 5.2

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration can go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded after loading
    # the framework and any gems in your application.
    config.autoload_paths += ["#{config.root}/lib", "#{config.root}/app/notices", "#{config}/app/jobs"]
  end
end

