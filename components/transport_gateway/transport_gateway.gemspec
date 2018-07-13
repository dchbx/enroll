$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "transport_gateway/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "transport_gateway"
  s.version     = TransportGateway::VERSION
  s.authors     = ["Dan Thomas"]
  s.email       = ["dan@ideacrew.com"]
  s.homepage    = "https://github.com/dchbx"
  s.summary     = %q{A gateway for receiving and forwarding messages over various protocols}
  s.description = %q{A gateway that abstracts and transmits message payloads over SMTP, SFTP, HTTP, file and other protocols}
  s.license     = "MIT"

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.rdoc"]

  s.add_dependency 'rails', '>= 4.2.0'
  s.add_dependency 'net-sftp', '~> 2.1', '>= 2.1.2'
  s.add_dependency 'aws-sdk', '>= 2.2.4'

  s.add_development_dependency 'rspec-rails'
  s.add_development_dependency 'shoulda-matchers'
  s.add_development_dependency 'webmock'
  s.add_development_dependency 'rspec'
end
