require File.join(Rails.root, "app", "data_migrations", "map_dental_plans")
# This rake task is to add employee role
# RAILS_ENV=production bundle exec rake migrations:map_dental_plans previous_year=2016 current_year=2017
namespace :migrations do
  desc "map previous year dental plans with current year dental plans"
  MapDentalPlans.define_task :map_dental_plans => :environment
end