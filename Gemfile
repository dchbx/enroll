source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '2.5.1'
gem 'rails', '~> 5.2.3'

#######################################################
# FIXME
#######################################################

# Update to use features from new version
gem 'effective_datatables', path: './project_gems/effective_datatables-2.6.14'
# gem 'jquery-datatables-rails', '3.4.0'config/initializers/effective_datatables.rb

# Verify this gem git reference is necessary.  Otherwise point it to release level
gem 'prawn', :git => 'https://github.com/prawnpdf/prawn.git', :ref => '8028ca0cd2'

## Fix this dependency -- bring into project
# gem 'recurring_select', :git => 'https://github.com/brianweiner/recurring_select'

## Fix this dependency -- bring into project
gem 'simple_calendar', :git => 'https://github.com/harshared/simple_calendar.git'

## Verify Rails 5 eliminates need for this gem with MongoDB
gem 'database_cleaner',       '~> 1.7'

#######################################################

#######################################################
# Local components/engines
#######################################################
gem 'acapi',              git: "https://github.com/dchbx/acapi.git", branch: 'master'
gem "benefit_markets",    path: "components/benefit_markets"
gem "benefit_sponsors",   path: "components/benefit_sponsors"
gem 'openhbx_cv2',        git: 'https://github.com/dchbx/openhbx_cv2.git', branch: 'master'
gem "notifier",           path: "components/notifier"
gem "sponsored_benefits", path: "components/sponsored_benefits"
gem "transport_gateway",  path: "components/transport_gateway"
gem "transport_profiles", path: "components/transport_profiles"
#######################################################

## MongoDB gem dependencies
gem 'bson',                     '~> 4.3'
gem 'carrierwave-mongoid',      '~> 1.2',  :require => 'carrierwave/mongoid'
gem 'mongoid',                  '~> 7.0.2'
gem 'mongo',                    '~> 2.6'
gem 'mongo_session_store',      '~> 3.1'
gem 'mongoid-autoinc',          '~> 6.0'
gem 'mongoid-history',          '~> 0.8'
# gem 'mongoid-versioning',       '~> 1.2.0'
gem 'mongoid_userstamp',        '~> 0.4', :path => "./project_gems/mongoid_userstamp-0.4.0"
gem 'mongoid_rails_migrations', '~> 1.2'

## General gems
gem 'aasm',                     '~> 4.8'
gem 'addressable',              '~> 2.3'
gem 'animate-rails',            '~> 1.0.10'
gem 'recurring_select'

gem 'aws-sdk',                  '~> 2.2.4'
gem 'bcrypt',                   '~> 3.1'
gem 'bootsnap',                 '>= 1.1', require: false
gem 'ckeditor',                 '~> 4.2.4'
gem 'coffee-rails',             '~> 4.2.2'
gem 'combine_pdf',              '~> 1.0'
gem 'config',                   '~> 1.0'
gem 'curl',                     '~> 0.0.9'
gem 'devise',                   '~> 4.5'
gem 'haml',                     '~> 5.0'
gem 'httparty',                 '~> 0.16'
gem 'i18n',                     '~> 1.5'
gem 'interactor',               '~> 3.0'
gem 'interactor-rails',         '~> 2.2'
gem 'jbuilder',                 '~> 2.7'
gem 'jquery-rails',             '~> 4.3'
gem 'kaminari',                 '~> 0.17'
gem 'kaminari-mongoid',         '~> 1.0'
gem 'language_list',            '~> 1'
gem 'mail',                     '~> 2.7'
gem 'maskedinput-rails',        '~> 1.4'
gem 'money-rails',              '~> 1.13'
gem 'net-ssh',                  '= 4.2.0'
gem 'nokogiri',                 '~> 1.10'
gem 'nokogiri-happymapper',     '~> 0.8.0', :require => 'happymapper'
gem 'pundit',                   '~> 2.0'
gem "recaptcha",                '~> 4.13', require: 'recaptcha/rails'
gem 'redcarpet',                '~> 3.4'
gem 'redis',                    '~> 4.0'
gem 'redis-rails',              '~> 5.0.2'
gem 'resque',                   '~> 2.0'
gem 'roo',                      '~> 2.1'
gem 'ruby-saml',                '~> 1.3'
gem 'sassc',                    '~> 1.12'
gem 'sass-rails',               '~> 5'
gem 'slim',                     '~> 3.0'
gem 'slim-rails',               '~> 3.2'
gem 'symmetric-encryption',     '~> 3.9.1'
gem 'turbolinks',               '~> 5'
gem 'uglifier',                 '>= 4'
gem 'virtus',                   '~> 1.0'
gem 'wicked_pdf',               '~> 1.1.0'
gem 'wkhtmltopdf-binary-edge',  '~> 0.12.3.0'
gem 'webpacker',                '~> 4.0.2'


group :doc do
  gem 'sdoc',                   '~> 1.0'
end

group :development do
  gem "certified",              '~> 1'
  gem 'overcommit',             '~> 0.47'
  gem 'rubocop',                require: false
  gem 'rubocop-rspec'
  gem 'rubocop-git'


  # Access an interactive console on exception pages or by calling 'console' anywhere in the code.
  gem 'web-console',            '>= 3'
  gem 'listen',                 '>= 3.0.5', '< 3.2'

  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring',                 '~> 1.6'
  gem 'spring-watcher-listen',  '~> 2.0'
end

group :development, :test do
  # gem 'bundler-audit',          '~> 0.6'
  gem 'capistrano',             '~> 3.1'
  gem 'capistrano-rails',       '1.4'
  gem 'email_spec',             '~> 2'
  gem 'factory_bot_rails',      '~> 4.11'
  gem 'forgery',                '~> 0.7.0'
  gem 'parallel_tests',         '~> 2.26.2'
  gem 'puma',                   '~> 3.11'
  gem 'railroady',              '~> 1.5.3'
  gem 'rspec-rails'
  gem 'rspec_junit_formatter'
  gem 'yard',                   '~> 0.9.12',  require: false
  gem 'yard-mongoid',           '~> 0.1',     require: false
  gem 'rails-controller-testing'
  gem 'climate_control', '~> 0.2.0'
end

group :test do
  gem 'action_mailer_cache_delivery', '~> 0.3'
  gem 'capybara',                     '~> 3.12'
  gem 'capybara-screenshot',          '~> 1.0.18'
  gem 'cucumber',                     '~> 3'
  gem 'cucumber-rails',               '~> 1.6',   :require => false
  gem 'fakeredis',                    '~> 0.7.0', :require => 'fakeredis/rspec'
  gem 'mongoid-rspec',                '~> 4'
  gem 'poltergeist',                  '~> 1.18.0'
  gem 'rspec-instafail',              '~> 1'
  gem 'ruby-progressbar',             '~> 1'
  gem 'shoulda-matchers',             '~> 3'
  gem 'simplecov',                    '~> 0.14',  :require => false
  gem 'test-prof',                    '~> 0.5.0'
  gem 'warden',                       '~> 1.2.7'
  gem 'watir',                        '~> 6.10.3'
  gem 'webdrivers',                   '~> 3.0'
  gem 'webmock',                      '~> 3.0.1'
end

group :production do
  gem 'eye',          '0.8'
  gem 'newrelic_rpm', '~> 5.0'
  gem 'unicorn',      '~> 4.8'
end

#######################################################
## Rails 5 Migration
#######################################################

#######################################################
# Upgraded gems
#######################################################
# gem 'aws-sdk',        '~> 2.2.4'
# gem 'coffee-rails', '~> 4.1.0'
# gem 'cucumber', '2.3.3'
# gem 'devise', '>= 3.5.4'
# gem 'Factory_bot_rails', '4.6.0'
# gem 'jbuilder', '~> 2.0'
# gem 'mongoid', '~> 5.4.0'
# gem 'mongoid_rails_migrations', git: 'https://github.com/adacosta/mongoid_rails_migrations.git', branch: 'master'
# gem 'nokogiri', '1.6.7.2'
# gem 'pundit', '~> 1.0.1'
# gem 'rails', '4.2.7.1'
# gem 'rails-i18n', '4.0.8'
# gem "recaptcha", '4.3.1', require: 'recaptcha/rails'
# gem 'rspec-rails', '~> 3.4.2'
# gem 'sdoc', '~> 0.4.0'
# gem 'turbolinks', '2.5.3'
# gem 'effective_datatables', '~> 2.6.14'
#######################################################

#######################################################
# Removed gems
#######################################################
# gem 'bootstrap-multiselect-rails', '~> 0.9.9'
# gem 'bootstrap-slider-rails', '6.0.17'
# gem 'bootstrap',                '~> 4.1'
# gem 'chosen-rails'
# gem 'jquery-turbolinks'
# gem 'jquery-ui-rails'
# gem 'less-rails-bootstrap', '~> 3.3.1.0'
# gem 'mongoid-enum'
# gem 'non-stupid-digest-assets', '~> 1.0', '>= 1.0.9'
# gem 'redis-rails',  '~> 5.0.2'
# gem 'sass-rails', '~> 5.0'
# gem 'sprockets', '~> 2.12.3'
# gem 'therubyracer', '~> 0.12.3', platforms: :ruby
# gem 'selenium-webdriver', '3.141.0'
#######################################################
