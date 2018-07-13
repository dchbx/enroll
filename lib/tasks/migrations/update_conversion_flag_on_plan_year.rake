# Rake task to update Update Conversion Flag
# To run rake task: RAILS_ENV=production bundle exec rake migrations:update_plan_year_conversion_flag fein="522111704, 300266649, 260077227"
require File.join(Rails.root, "app", "data_migrations", "update_plan_year_conversion_flag")

namespace :migrations do
  desc "Updating conversion flag on plan year by validating all employers profile source"
  UpdatePlanYearConversionFlag.define_task :update_plan_year_conversion_flag => :environment
end