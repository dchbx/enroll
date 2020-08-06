# frozen_string_literal: true

require 'virtus'

module SponsoredBenefits
  class Engine < ::Rails::Engine
    isolate_namespace SponsoredBenefits

    initializer "sponsored_benefits.factories", :after => "factory_bot.set_factory_paths" do
      FactoryBot.definition_file_paths << File.expand_path('../../../../../spec/factories', __FILE__) if defined?(FactoryBot)
      FactoryBot.definition_file_paths << File.expand_path('../../../spec/factories', __FILE__) if defined?(FactoryBot)
    end

    config.generators do |g|
      g.orm :mongoid
      g.template_engine :slim
      g.test_framework :rspec, :fixture => false
      g.fixture_replacement :factory_bot, :dir => 'spec/factories'
      g.assets false
      g.helper false
    end
  end
end
