require File.expand_path('../boot', __FILE__)

# require 'rails/all'
require "action_controller/railtie"
require "action_mailer/railtie"
require "rails/test_unit/railtie"
require "sprockets/railtie" # Uncomment this line for Rails 3.1+

# Configure fallbacks for mongoid errors:
require "i18n/backend/fallbacks"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

require File.join(File.dirname(__FILE__), "json_log_format")

module Enroll
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.
    config.autoload_paths += %W(#{config.root}/lib #{config.root}/app/notices)
    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    config.i18n.available_locales = [:en, :es]
    config.i18n.default_locale = :en

    # Do not swallow errors in after_commit/after_rollback callbacks.
    # config.active_record.raise_in_transactional_callbacks = true
    config.assets.enabled = true
    config.assets.paths << "#{Rails.root}/app/assets/info"
    
    I18n::Backend::Simple.send(:include, I18n::Backend::Fallbacks)
    config.i18n.fallbacks = {'es' => 'en'}
    config.paths.add "app/api", glob: "**/*.rb"
    config.autoload_paths += Dir["#{Rails.root}/app/api/api/*/*"]

    #Thanks to Wojtek Kruszewski: https://gist.github.com/WojtekKruszewski
    config.log_tags = [    #'-anything',
      ->(req){
        SessionTaggedLogger.extract_session_id_from_request(req)
      }
    ]

    unless Rails.env.test?
      config.acapi.add_subscription("Events::ResidencyVerificationRequestsController")
      config.acapi.add_subscription("Events::SsaVerificationRequestsController")
      config.acapi.add_subscription("Events::VlpVerificationRequestsController")
      config.acapi.add_async_subscription("Subscribers::DateChange")
      config.acapi.add_async_subscription("Subscribers::SsaVerification")
      config.acapi.add_async_subscription("Subscribers::LawfulPresence")
      config.acapi.add_async_subscription("Subscribers::LocalResidency")
      config.acapi.add_async_subscription("Subscribers::FamilyApplicationCompleted")
      config.acapi.add_async_subscription("Subscribers::NotificationSubscriber")
      config.acapi.add_async_subscription("Subscribers::DefaultGaChanged")
    end
  end
end
