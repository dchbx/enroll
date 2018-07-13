require 'active_model_serializers'
require 'slim'
require 'effective_datatables'
require 'virtus'
require 'devise'
require 'pundit'
require 'language_list'

module BenefitSponsors
  class Engine < ::Rails::Engine
    isolate_namespace BenefitSponsors

    initializer "benefit_sponsors.factories", :after => "factory_girl.set_factory_paths" do
      FactoryGirl.definition_file_paths << File.expand_path('../../../spec/factories', __FILE__) if defined?(FactoryGirl)
    end

    config.generators do |g|
      g.orm :mongoid
      g.template_engine :slim
      g.test_framework :rspec, :fixture => false
      g.fixture_replacement :factory_girl, :dir => 'spec/factories'
      g.assets false
      g.helper true
    end

    config.to_prepare do
#      BenefitSponsors::ApplicationController.helper Rails.application.helpers
    end
  end
end
