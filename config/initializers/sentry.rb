# frozen_string_literal: true

Raven.configure do |config|
  config.current_environment = ENV["AWS_ENV"] || 'sandbox'
  config.dsn = ENV["SENTRY_DSN"]
end
