$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem"s version:
require "aca/shop/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name          = "aca_shop"
  s.version       = Aca::Shop::VERSION
  s.authors       = ["Dan Thomas", "Bill Transue"]
  s.description   = %q{An Enroll App extension that supports the ACA Small Business Health Options Program (SHOP) Marketplace}
  s.summary       = "ACA SHOP Market gem"
  s.homepage      = "https://github.com/dchbx"
  s.license       = "MIT"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if s.respond_to?(:metadata)
    s.metadata['allowed_push_host'] = "TODO: Set to 'http://mygemserver.com'"
  else
    raise "RubyGems 2.0 or newer is required to protect against " \
      "public gem pushes."
  end

  s.files = Dir["{app,config,db,lib}/**/*"] + ["MIT-LICENSE", "Rakefile", "README.rdoc"]

  # s.add_runtime_dependency "activesupport", [">= 3.2"]
  s.add_dependency "rails", "4.2.3"
  s.add_dependency "sass-rails", "5.0.4"
  s.add_dependency "jquery-rails", "4.0.5"

  s.add_dependency "mongoid", "5.0.1"
  s.add_dependency "symmetric-encryption", "~> 3.6.0"
  s.add_dependency "aasm", "~> 4.8.0"
  s.add_dependency "pundit", "~> 1.0.1"
  s.add_dependency "rails-i18n", "4.0.8"

  s.add_development_dependency "spring", "1.6.3"
  s.add_development_dependency "byebug"
  s.add_development_dependency "rspec-rails", "3.4.2"
  s.add_development_dependency "factory_girl_rails", "4.6.0"

  s.add_development_dependency "capybara", "2.6.2"
  s.add_development_dependency "shoulda-matchers", "3.1.1"
  s.add_development_dependency "poltergeist", "1.11.0"

  s.metadata["yard.run"] = "yri" # use "yard" to build full HTML docs.
end
