# Rake task to change Gender of an Employee
# To run rake task: RAILS_ENV=production bundle exec rake migrations:cancel_plan_years_group file_name="CancelPlanYears.csv"

require File.join(Rails.root, "app", "data_migrations", "cancel_plan_years_group")
namespace :migrations do
  desc "Cancel Plan Years Group"
  CancelPlanYearsGroup.define_task :cancel_plan_years_group => :environment
end
