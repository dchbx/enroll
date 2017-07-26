require File.join(Rails.root, "app", "data_migrations", "add_family_member_to_coverage_household")
# RAILS_ENV=production bundle exec rake migrations:add_family_member_to_coverage_household hbx_id=19810927
namespace :migrations do
  desc "add family member to coverage household"
  AddFamilyMemberToCoverageHousehold.define_task :add_family_member_to_coverage_household => :environment
end