# frozen_string_literal: true

$LOAD_PATH.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "financial_assistance/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |spec|
  spec.name        = "financial_assistance"
  spec.version     = FinancialAssistance::VERSION
  spec.authors     = ["Dan Thomas"]
  spec.email       = ["dan.thomas@dc.gov"]
  spec.homepage    = "https://github.com/ideacrew"
  spec.summary     = "Summary of FinancialAssistance."
  spec.description = "Description of FinancialAssistance."
  spec.license     = "MIT"

  spec.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]
  spec.test_files = Dir["spec/**/*"]

  spec.add_dependency "rails",                     "~> 5.2.3"
  spec.add_dependency "mongoid",                   "~> 7.0.2"
  spec.add_dependency 'mongoid-autoinc',           '~> 6.0'
  spec.add_dependency "aasm",                      "~> 4.8"
  spec.add_dependency 'config',                    '~> 2.0'
  spec.add_dependency 'devise',                    '~> 4.5'
  spec.add_dependency 'money-rails',               '~> 1.13.3'
  spec.add_dependency "slim",                      "~> 3.0"
  spec.add_dependency 'symmetric-encryption',      '~> 3.9.1'
  spec.add_dependency 'pundit',                    '~> 2.0'
  spec.add_dependency 'font-awesome-rails',        '~> 4.7'
  spec.add_dependency 'haml-rails'
  spec.add_dependency 'dry-types'
  spec.add_dependency 'dry-validation'
  spec.add_dependency 'dry-monads'

  spec.add_development_dependency 'capybara',                  '~> 3.12'
  spec.add_development_dependency 'database_cleaner-mongoid'
  spec.add_development_dependency 'factory_bot_rails',         '~> 4'
  spec.add_development_dependency 'forgery',                   '~> 0.7.0'
  spec.add_development_dependency 'mongoid_rails_migrations',  '~> 1.2.0'
  spec.add_development_dependency "mongoid-rspec",             '~> 4.0.1'
  spec.add_development_dependency 'rails-perftest',            '~> 0.0.7'
  spec.add_development_dependency "rspec-rails",               '~> 3.8'
  spec.add_development_dependency 'rubocop-rspec',             '~> 1.31'
  spec.add_development_dependency 'shoulda-matchers',          '~> 3'
  spec.add_development_dependency 'test-prof',                 '~> 0.5.0'
  spec.add_development_dependency 'pry-byebug'
  spec.add_development_dependency "yard"

end