require File.join(Rails.root, "app", "data_migrations", "update_plan_years_with_dental_offerings")

# RAILS_ENV=production bundle exec rake migrations:update_plan_years_with_dental_offerings calender_month=5

namespace :migrations do
  desc "Update renewal plan years with dental offerings"
  UpdatePlanYearsWithDentalOfferings.define_task :update_plan_years_with_dental_offerings => :environment
end
