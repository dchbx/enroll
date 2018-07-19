module BenefitMarkets
  class Engine < ::Rails::Engine
    isolate_namespace BenefitMarkets

    initializer "benefit_markets.factories", :after => "factory_girl.set_factory_paths" do
      FactoryGirl.definition_file_paths << File.expand_path('../../../spec/factories', __FILE__) if defined?(FactoryGirl)
    end

    config.generators do |g|
      g.orm :mongoid
      g.template_engine :slim
      g.test_framework :rspec, :fixture => false
      g.fixture_replacement :factory_girl, :dir => 'spec/factories'
      g.assets false
      g.helper false
    end

    config.to_prepare do
      BenefitMarkets::ApplicationController.helper Rails.application.helpers
    end

    # config.before_initialize do
    #   Dir.glob(Rails.root + "app/models/**/*time_keeper*.rb").each do |c|
    #     require_dependency(c)
    #   end
    # end

    # initializer 'admin.append_migrations' do |app|
    #   unless app.root.to_s == root.to_s
    #     config.paths["db/migrate"].expanded.each do |path|
    #       app.config.paths["db/migrate"].push(path)
    #     end
    #   end
    # end

  end
end
