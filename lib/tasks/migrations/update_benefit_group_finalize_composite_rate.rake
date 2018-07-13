# Rake tasks used to calculate benefit_group finalize_composite_rate
# To run rake task: RAILS_ENV=production bundle exec rake migrations:calculate_benefit_group_finalize_composite_rate fein=271441903 plan_year_start_on=05/01/2017
require File.join(Rails.root, "app", "data_migrations", "update_benefit_group_finalize_composite_rate")

namespace :migrations do
  desc "calculate benefit_group finalize_composite_rate"
  UpdateBenefitGroupFinalizeCompositeRate.define_task :calculate_benefit_group_finalize_composite_rate => :environment
end