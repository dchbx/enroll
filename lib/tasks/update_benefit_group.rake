require File.join(Rails.root, "app", "data_migrations", "update_benefit_group")
# This rake task is to add active benefit group to EE if EE has renewal benefit group and without active one
# The rake task is RAILS_ENV=production bundle exec rake update:update_benefit_group

namespace :update do
  desc "changing is active field for benefit group assignment"
  UpdateBenefitGroup.define_task :update_benefit_group => :environment
end
