require File.join(Rails.root, "app", "data_migrations", "cancel_plan_year")

# RAILS_ENV=production bundle exec rake migrations:cancel_plan_year fein=112777622 plan_year_state="draft"

namespace :migrations do
  desc "cancel plan year"
  CancelPlanYear.define_task :cancel_plan_year => :environment
end 
