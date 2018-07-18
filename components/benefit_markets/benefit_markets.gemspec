$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "benefit_markets/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "benefit_markets"
  s.version     = BenefitMarkets::VERSION
  s.authors     = ["IdeaCrew"]
  s.email       = ["enroll_app@ideacrew.com"]
  s.homepage    = "https://github.com/dchbx"
  s.summary     = "Create and manage markets that enable benefit sponsors to access products and offer benefits to their members."
  s.description = "Create and manage markets that enable benefit sponsors to access products and offer benefits to their members."
  s.license     = "MIT"

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.rdoc"]
  s.test_files = Dir["spec/**/*"]

  s.add_dependency "rails", "~> 4.2.7.1"
  s.add_dependency "slim", "~> 3.0.9"
  s.add_dependency "mongoid", "~> 5.4.0"
  # s.add_dependency 'mongoid-multitenancy', '~> 1.2'
  s.add_dependency "aasm", "~> 4.8.0"
  s.add_dependency 'config'
  s.add_dependency 'symmetric-encryption', '~> 3.6.0'
  s.add_dependency 'pundit', '~> 1.0.1'
  s.add_dependency 'active_model_serializers'
  s.add_dependency 'virtus'

  s.add_development_dependency "rspec-rails"
  s.add_development_dependency 'shoulda-matchers'
  s.add_development_dependency 'database_cleaner'
  s.add_development_dependency 'capybara'
  s.add_development_dependency 'factory_girl_rails'
  s.add_development_dependency 'pry'
  s.add_development_dependency 'pry-rails'
  s.add_development_dependency 'pry-stack_explorer'
  s.add_development_dependency 'pry-byebug'
  s.add_development_dependency 'pry-remote'
  s.add_development_dependency 'forgery'
  s.add_development_dependency 'mongoid_rails_migrations'
end

