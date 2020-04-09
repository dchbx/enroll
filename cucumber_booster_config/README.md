# Cucumber Booster Config

[![Build Status](https://semaphoreci.com/api/v1/projects/b5ad1293-4dd1-425d-8c00-b42ceca09c75/527737/badge.svg)](https://semaphoreci.com/renderedtext/cucumber_booster_config)
[![Gem Version](https://badge.fury.io/rb/semaphore_cucumber_booster_config.svg)](https://badge.fury.io/rb/semaphore_cucumber_booster_config)

Injects additional configuration for Cucumber so that it outputs JSON report suitable
for estimation of the [split configuration](https://github.com/renderedtext/test-boosters#split-configuration) for the next build.

Cucumber Booster Config is primarily used as [Test Boosters gem](https://github.com/renderedtext/test-boosters) dependency.
Boosters help you with distribution of your test files across many parallel jobs and optimize your build time. Find out more about [Boosters](https://semaphoreci.com/docs/about-boosters.html).

## Installation

Add this line to your application's Gemfile:

```ruby
gem "semaphore_cucumber_booster_config"
```

## Usage from the CLI

```
$ cucumber-booster-config help inject
Usage:
  cucumber-booster-config inject PATH

  Options:
    [--dry-run], [--no-dry-run]

inject Semaphore's Cucumber configuration in project PATH
```

If you use the `--dry-run` option, output will look like this:

```
$ cucumber-booster-config inject . --dry-run
Running in .
Found Cucumber profile file: ./cucumber.yml
Content before:
---
default: --format pretty features
---
Inserting Semaphore configuration at the top
Appending Semaphore profile to default profile
Content after:
---
semaphoreci: --format json --out=features_report.json
default: --format pretty features --profile semaphoreci
---
```

## Usage from other scripts

You can invoke the injector script programaticaly too:

``` ruby
current_path = Dir.pwd
output_report_path = "/tmp/cucumber_report.json"

CucumberBoosterConfig::Injection.new(current_path, output_report_path).run
```

This is how Test Boosters gem is using it to configure Cucumber.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run
`bundle exec rspec` to run the tests. You can also run `bin/console` for an
interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`.

### How to release a new version

Bump version number in `lib/cucumber_booster_config/version.rb`, commit and
push your changes.

Semaphore is currently configured to push new versions to Rubygems.
If version hasn't changed, Rubygems will simply ignore the update.

## Contributing

Bug reports and pull requests are welcome on GitHub at
https://github.com/renderedtext/cucumber_booster_config.

## License

The gem is available as open source under the terms of the [MIT license](LICENSE).
