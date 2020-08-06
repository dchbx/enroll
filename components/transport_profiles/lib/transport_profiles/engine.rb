# frozen_string_literal: true

module TransportProfiles
  class Engine < ::Rails::Engine
    isolate_namespace TransportProfiles

    config.generators do |g|
      g.orm :mongoid
      g.test_framework :rspec, :fixture => false
      g.fixture_replacement :Factory_bot, :dir => 'spec/factories'
      g.assets false
      g.helper false
    end
  end
end
