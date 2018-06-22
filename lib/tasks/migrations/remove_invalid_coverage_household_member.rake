# Rake to remove invalid coverage household member
# RAILS_ENV=production bundle exec rake migrations:remove_invaild_coverage_household_member person_hbx_id=19892737 family_member_id="5acb6fdd082e7617bc000192" coverage_household_member_id="58b05e88f209f2831300001f"
require File.join(Rails.root, "app", "data_migrations", "remove_invalid_coverage_household_member")
namespace :migrations do
  desc "removefamily member from coverage household"
  RemoveInvalidCoverageHouseholdMember.define_task :remove_invalid_coverage_household_member => :environment
end