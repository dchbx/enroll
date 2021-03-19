$LOAD_PATH.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "sponsored_benefits/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "sponsored_benefits"
  s.version     = SponsoredBenefits::VERSION
  s.authors     = ["raghuram"]
  s.email       = ["raghuramg83@gmail.com"]
  s.homepage    = "https://github.com/ideacrew"
  s.summary     = "Summary of SponsoredBenefits."
  s.description = "Description of SponsoredBenefits."
  s.license     = "MIT"

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.rdoc"]

  s.add_dependency "rails", "~> 5.2.4.3"
  s.add_dependency "slim", "~> 3.0.8"
  s.add_dependency "mongoid", "~> 7.0.2"
  s.add_dependency "aasm", "~> 4.8.0"
  s.add_dependency 'devise',                    '~> 4.5'
  s.add_dependency 'config',  '~> 2.0'
  s.add_dependency 'symmetric-encryption', '~> 3.9.1'
  s.add_dependency 'roo', '~> 2.1.0'
  s.add_dependency 'pundit',                    '~> 2.0'
  s.add_dependency 'ffi', '~> 1.9'
  s.add_dependency 'kaminari', '~> 0.17.0'
  s.add_dependency 'sass', '~> 3.7.3'
  s.add_dependency 'webpacker',                 '~> 4.0.2'
  s.add_dependency 'dry-types'
  s.add_dependency 'dry-schema', '~> 1.0'
  s.add_dependency 'dry-validation', '~> 1.0'
  s.add_dependency 'dry-initializer'
  s.add_dependency 'dry-auto_inject', '0.6.1'
  s.add_dependency 'dry-container'
  s.add_dependency 'dry-struct'
  s.add_dependency 'dry-monads'

  s.test_files = Dir["spec/**/*"]

  s.add_development_dependency "rspec-rails"
  s.add_development_dependency 'shoulda-matchers',          '~> 3'
  s.add_development_dependency 'database_cleaner-mongoid'
  s.add_development_dependency 'capybara',                  '~> 3.12'
  s.add_development_dependency 'factory_bot_rails',         '~> 4'
  s.add_development_dependency 'forgery',                   '~> 0.7.0'
  s.add_development_dependency 'test-prof',                 '~> 0.5.0'
  s.add_development_dependency "mongoid-rspec",             '~> 4'
  s.add_development_dependency 'mongoid_rails_migrations',  '~> 1.2.0'
  s.add_development_dependency "rspec-benchmark"
end
