# frozen_string_literal: true

require 'slim'
require 'devise'
require 'pundit'
require 'dry-container'

module FinancialAssistance
  class Engine < ::Rails::Engine
    isolate_namespace FinancialAssistance

    config.autoload_paths += Dir[root.join("app/domain/**")]

    initializer "financial_assistance.factories", :after => "Factory_bot.set_factory_paths" do
      FactoryBot.definition_file_paths << File.expand_path('../../../spec/factories', __FILE__) if defined?(FactoryBot)
    end

    config.generators do |g|
      g.orm :mongoid
      g.test_framework :rspec, :fixture => false
      g.fixture_replacement :Factory_bot, :dir => 'spec/factories'
      g.assets false
      g.helper true
    end

    # config.to_prepare do
    #  FinancialAssistance::ApplicationController.helper Rails.application.helpers
    # end
  end
end
