require File.join(Rails.root, "app", "data_migrations", "update_cat_age_off_plan_mapping")

namespace :migrations do
  desc "update catastrophic age off mapping"
  UpdateCatAgeOffPlanMapping.define_task :cat_age_off_renewal_plan => :environment
end