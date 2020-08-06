# frozen_string_literal: true

# require 'active_model_serializers'
require 'slim'
require 'effective_datatables'
require 'virtus'
require 'devise'
require 'pundit'
require 'language_list'
require 'interactor'
require 'dry-container'
require 'dry-auto_inject'

module BenefitSponsors
  class Engine < ::Rails::Engine
    isolate_namespace BenefitSponsors

    initializer "benefit_sponsors.factories", :after => "Factory_bot.set_factory_paths" do
      FactoryBot.definition_file_paths << File.expand_path('../../../spec/factories', __FILE__) if defined?(FactoryBot)
    end

    config.autoload_paths << File.expand_path(File.join(File.dirname(__FILE__), "..", "..", "app/validators"))

    config.generators do |g|
      g.orm :mongoid
      g.template_engine :slim
      g.test_framework :rspec, :fixture => false
      g.fixture_replacement :Factory_bot, :dir => 'spec/factories'
      g.assets false
      g.helper true
    end

    config.to_prepare do
#      BenefitSponsors::ApplicationController.helper Rails.application.helpers
    end
  end
end
