$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "ui_helpers/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "ui_helpers"
  s.version     = UIHelpers::VERSION
  s.authors     = ["Bill Transue"]
  s.email       = ["transue@gmail.com"]
  s.summary     = "UI Helpers for your views"

  s.files = Dir["{app,config,db,lib}/**/*", "Rakefile", "README.rdoc"]

  s.add_dependency "rails", "~> 4.2.3"

  s.add_development_dependency "sqlite3"
end
