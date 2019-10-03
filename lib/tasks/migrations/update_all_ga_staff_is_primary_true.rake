# Rake task to update all general agency staff role's is_primary attribute to true
# To run rake task: RAILS_ENV=production bundle exec rake migrations:update_all_ga_staff_is_primary_true
require File.join(Rails.root, "app", "data_migrations", "update_all_ga_staff_is_primary_true")

namespace :migrations do
  desc "Updating the aasm_state of benefit sponsorships and benefit applications"
  UpdateAllGaStaffIsPrmaryTrue.define_task :update_all_ga_staff_is_primary_true => :environment
end
