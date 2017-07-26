require File.join(Rails.root, "app", "data_migrations", "change_new_hire_rule")
# This rake task is to change the effective on kind from "date-of hire" to "first_of_month" for benefit group
# RAILS_ENV=production bundle exec rake migrations:change_new_hire_rule fein=451173603 plan_year_state="expired"
namespace :migrations do
  desc "changing effective on kind for benefit group"
  ChangeNewHireRule.define_task :change_new_hire_rule => :environment
end 