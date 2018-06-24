# Rake task to interchange
# To run rake task: RAILS_ENV=production bundle exec rake migrations:update_benefit_group_id enrollment_hbx_id="123456789" benefit_group_id="5d0f98a10200"

require File.join(Rails.root, "app", "data_migrations", "update_benefit_group_id")
namespace :migrations do
  desc "update_benefit_group_id"
  UpdateBenefitGroupId.define_task :update_benefit_group_id => :environment
end