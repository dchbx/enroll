$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "sponsored_benefits/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "sponsored_benefits"
  s.version     = SponsoredBenefits::VERSION
  s.authors     = ["raghuram"]
  s.email       = ["raghuramg83@gmail.com"]
  s.homepage    = "https://github.com/dchbx"
  s.summary     = "Summary of SponsoredBenefits."
  s.description = "Description of SponsoredBenefits."
  s.license     = "MIT"

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.rdoc"]

  s.add_dependency "rails", "~> 4.2.7.1"
  s.add_dependency "slim", "3.0.8"
  s.add_dependency "mongoid", "~> 5.0.1"
  s.add_dependency "aasm", "~> 4.8.0"
  s.add_dependency 'config'
  s.add_dependency 'symmetric-encryption', '~> 3.6.0'
  s.add_dependency 'roo', '~> 2.1.0'

  s.test_files = Dir["spec/**/*"]

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
end
