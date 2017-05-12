$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem"s version:
require "aca/individual/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "aca-individual"
  s.version     = ACA::Indvidiual::VERSION
  s.authors     = "Bill Transue"
  s.summary     = "ACA Indvidiual gem"
  s.description = "ACA Indvidiual gem"

  s.files = Dir["{app,config,db,lib}/**/*"] + ["MIT-LICENSE", "Rakefile", "README.rdoc"]

  s.add_dependency "rails", "4.2.3"
  s.add_dependency "haml-rails", "0.9.0"
  s.add_dependency "sass-rails", "5.0.4"
  s.add_dependency "jquery-rails", "4.0.5"

  s.add_development_dependency "rspec-rails", "3.4.2"
  s.add_development_dependency "capybara", "2.6.2"
  s.add_development_dependency "shoulda-matchers", "3.1.1"
  s.add_development_dependency "poltergeist", "1.11.0"
end
