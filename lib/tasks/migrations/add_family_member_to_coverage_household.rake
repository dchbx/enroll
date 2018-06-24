# RAILS_ENV=production bundle exec rake migrations:add_family_member_to_coverage_household primary_hbx_id=1234 dependent_hbx_id=5678
# To add primary to CHM, primary_hbx_id & dependent_hbx_id can be same

require File.join(Rails.root, "app", "data_migrations", "add_family_member_to_coverage_household")

namespace :migrations do
  desc "add family member to coverage household"
  AddFamilyMemberToCoverageHousehold.define_task :add_family_member_to_coverage_household => :environment
end