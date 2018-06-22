require File.join(Rails.root, "app", "data_migrations", "match_coverage_household_with_family_member")
# RAILS_ENV=production bundle exec rake migrations:match_coverage_household_with_family_member hbx_id=19810927
namespace :migrations do
  desc "match coverage household family member from family member"
  MatchCoverageHouseholdWithFamilyMember.define_task :match_coverage_household_with_family_member => :environment
end