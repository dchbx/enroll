require File.join(Rails.root, "app", "data_migrations", "create_new_initial_plan_year")
# This rake task is to create a new intial plan year
# RAILS_ENV=production bundle exec rake migrations:create_new_initial_plan_year fein=204895454 start_on=2015/12/1
namespace :migrations do
  desc "creating intial plan year"
  CreateNewInitialPlanYear.define_task :create_new_initial_plan_year => :environment
end
