# frozen_string_literal: true

# Rake task to extend broker application denial time
# To run rake task: RAILS_ENV=production bundle exec rake migrations:extend_broker_application broker_npn="123123"

require File.join(Rails.root, "app", "data_migrations", "extend_broker_application")
namespace :migrations do
  desc "Extends denial time of broker applications"
  ExtendBrokerApplication.define_task :extend_broker_application => :environment
end
