# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'cucumber_booster_config/version'

Gem::Specification.new do |spec|
  spec.name          = "semaphore_cucumber_booster_config"
  spec.version       = CucumberBoosterConfig::VERSION
  spec.authors       = ["Marko Anastasov"]
  spec.email         = ["marko@renderedtext.com"]

  spec.summary       = %q{Cucumber configuration injection for autoparallelism.}
  spec.description   = %q{Injects additional configuration for Cucumber so that it outputs JSON suitable for auto-parallelism without affecting stdout.}
  spec.homepage      = "https://github.com/renderedtext/cucumber_booster_config"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "thor", "~> 0.19.1"

  spec.add_development_dependency "bundler", "~> 1.10"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec"
end
