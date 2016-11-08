source 'https://rubygems.org'


# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '4.2.3'

# Use SCSS for stylesheets
gem 'sass-rails', '~> 5.0'

# Use Uglifier as compressor for JavaScript assets
gem 'uglifier', '>= 1.3.0'
# Use CoffeeScript for .coffee assets and views
gem 'coffee-rails', '~> 4.1.0'
# See https://github.com/sstephenson/execjs#readme for more supported runtimes
gem 'therubyracer', platforms: :ruby

# Use jquery as the JavaScript library
gem 'jquery-rails', '4.0.5'
gem 'jquery-ui-rails'
gem 'animate-rails', '~> 1.0.7'
gem 'maskedinput-rails'
# Turbolinks makes following links in your web application faster. Read more: https://github.com/rails/turbolinks
gem 'jquery-turbolinks'
gem 'turbolinks'

# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.0'

# JS graph API
# gem 'highcharts-rails', '~> 4.1', '>= 4.1.9'

# bundle exec rake doc:rails generates the API under doc/api.
gem 'sdoc', '~> 0.4.0', group: :doc
gem 'less-rails-bootstrap', '~> 3.3.1.0'
gem 'font-awesome-rails', '4.5.0.1'
gem 'nokogiri-happymapper', :require => 'happymapper'
gem 'nokogiri', '1.6.7.2'

gem 'mongoid', '5.0.1'
gem 'mongo', '2.1.2'
gem 'carrierwave-mongoid', :require => 'carrierwave/mongoid'
gem "mongoid-autoinc"
gem 'mongoid-versioning'

gem 'money-rails', '~> 1.3.0'
gem "mongoid-enum"
gem 'mongo_session_store-rails4', '~> 6.0.0'

## Add field-level encryption
# gem 'mongoid-encrypted-fields', '~> 1.3.3'
gem 'symmetric-encryption', '~> 3.6.0'

# Use ActiveModel has_secure_password
# gem 'bcrypt', '~> 3.1.7'

gem 'acapi', git: "https://github.com/dchbx/acapi.git", branch: 'development'
# gem 'acapi', path: "../acapi"

gem 'aasm', '~> 4.8.0'
gem 'haml'
# gem 'bh'

# spreadsheet support
gem 'roo', '~> 2.1.0'

# configuration support
gem "config", '~> 1.0.0'

gem 'devise', '~> 3.4.1'
# gem 'devise_ldap_authenticatable', '~> 0.8.1'
gem "pundit", '~> 1.0.1'

# will provide fast group premium plan fetch
gem 'redis-rails'

gem 'kaminari'

gem 'sprockets' , "~> 2.12.3"
# for I18n
gem 'rails-i18n', '4.0.8'
gem 'mail', '2.6.3'
gem 'bson', '3.2.6'
gem 'addressable', '2.3.8'
# gem 'rypt', '0.2.0'

gem 'language_list', '~> 1.1.0'
gem 'bootstrap-multiselect-rails', '~> 0.9.9'
gem 'bootstrap-slider-rails', '6.0.17'

gem 'prawn', :git => "https://github.com/prawnpdf/prawn.git", :ref => '8028ca0cd2'
gem 'virtus'
gem 'wkhtmltopdf-binary-edge', '~> 0.12.3.0'
gem 'wicked_pdf', '1.0.6'

# provide recaptcha services
gem "recaptcha", '1.1.0'

gem 'jquery-datatables-rails', '3.4.0'

gem 'interactor', '3.1.0'
gem 'interactor-rails', '2.0.2'

group :development do
  # Access an IRB console on exception pages or by using <%= console %> in views
  gem 'web-console', '2.3.0'
  gem "parallel_tests"
end

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'pry'
  gem 'pry-rails'
  gem 'pry-stack_explorer'
  gem 'pry-byebug'
  gem 'pry-remote'

  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring', '1.6.3'

  # Use Capistrano for deployment
  gem 'capistrano', '3.3.5'
  # gem 'capistrano-scm-gitcopy'
  gem 'capistrano-rails', '1.1.6'
  gem 'ruby-progressbar', '1.6.0'

  # Keep these in Development and Test environments for access by rails generators
  gem 'rspec-rails', '~> 3.4.2'
  gem 'factory_girl_rails', "4.6.0"
  gem 'forgery'
  gem 'email_spec', '2.0.0'
  gem 'byebug', '8.2.2'
  gem 'rspec_junit_formatter', '0.2.3'
end

group :test do
  gem 'mongoid-rspec', '3.0.0'
  gem 'watir'
  gem 'cucumber-rails', '~> 1.4.2', :require => false
  gem 'poltergeist'
  gem 'capybara-screenshot'
  gem 'database_cleaner', '1.5.1'
  gem 'shoulda-matchers', '3.1.1'
  gem 'action_mailer_cache_delivery', '~> 0.3.7'
  gem 'capybara', '2.6.2'
  gem 'warden'
end

group :production do
  # Use Unicorn as the app server
  gem 'unicorn', '~> 4.8.3'
  gem 'eye'

  # New Relic gem
  gem 'newrelic_rpm'

end

gem 'aws-sdk', '2.2.4'
gem 'ruby-saml', '~> 1.3.0'
gem 'combine_pdf'
