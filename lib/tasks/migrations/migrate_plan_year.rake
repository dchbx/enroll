require File.join(Rails.root, "app", "data_migrations", "migrate_plan_year")
# This rake task is to change the conversion ER's active or expired external plan year's status to migration expired state
# RAILS_ENV=production bundle exec rake migrations:migrate_plan_year fein=541748419
namespace :migrations do
  desc "changing conversion ER's plan year status to migration expired state"
  MigratePlanYear.define_task :migrate_plan_year => :environment
end 
