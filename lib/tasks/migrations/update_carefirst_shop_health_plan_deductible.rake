# this rake task is to update carefirst plan with proper deductibles.

require File.join(Rails.root, "app", "data_migrations", "update_carefirst_shop_health_plan_deductible")

# RAILS_ENV=production bundle exec rake migrations:update_carefirst_shop_health_plan_deductible
namespace :migrations do
  desc "update_carefirst_shop_health_plan_deductible"
  UpdateCarefirstShopHealthPlanDeductible.define_task :update_carefirst_shop_health_plan_deductible => :environment
end